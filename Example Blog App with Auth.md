# Example Blog App with Auth

 ## Pure Rails compared to Hyperloop

The purpose here is to show a high level overview of how Rails concepts map to Hyperloop concepts. It's not a full tutorial (I started doing that but it was way too long), but examples of key points.

## Auth

Here's a simple auth example, with a comment showing all you have to add to hook it up to Hyperloop. In a production app you'd probably use Devise, but the Hyperloop `acting_user` bit would be the same!

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_from_session

  private

  attr_reader :current_user

  def authenticate_from_session
    if (user_id = cookies.encrypted[:user_id])
      @current_user = User.find(user_id)
    end
  end

  def authenticate_user
    redirect_to new_session_path unless @current_user
  end

  # NOTE: For Hyperloop. All that's needed to hook up auth.
  def acting_user
    current_user
  end
end
```

```ruby
class User < ApplicationRecord
  has_secure_password
  # Add a Hyperloop channel connection - 
  # a user can connect to themself / see their own stuff
  regulate_instance_connections { self }

  has_one :blog
end
```



## Models

This example is for a blog app. So you'll have this simple setup:

```ruby
class User < ApplicationRecord
  has_secure_password

  has_one :blog
end

class Blog < ApplicationRecord
  belongs_to :user
  has_many :posts
end

class Post < ApplicationRecord
  belongs_to :blog
  has_many :comments
end

class Comment < ApplicationRecord
  belongs_to :post
end
```

```
[User] --- [Blog] --> [Post] --> [Comment]
```



## CRUD: Read

### Rails

In Rails to display some protected model data on the frontend you'll add a route, a controller with an auth before filter, and a view that displays your models.

Lets say we only want to display draft posts to the blog's owner.

```ruby
resources :blogs
```

```ruby
class BlogsController < ApplicationController
  def show
    @blog = Blog.find(params[:id])
    @posts = @blog.posts
    # Only show drafts to the blog's owner
    @posts.where(draft: false) unless current_user == @blog.user
  end
end
```

```erb
<h1><%= @blog.title %></h1>

<% @posts.each do |post| %>
  <h2><%= link_to post.title, post %></h2>
<% end %>
```



## Hyperloop

Hyperloop doesn't need controllers, and you can have just 1 route for the whole app. 

But without controllers where do we put our auth logic? Policies. You add a line to your model, declaring who is allowed to see what. Hyperloop then handles everything else—no need to repeat yourself in every controller.

In each model, you say who is allowed to see that model. How? Well in Rails auth you're working in a controller in a request, so you know the current_user and can think about things from their perspective. In Hyperloop we're in the model, no current request, so we tell Hyperloop everyone who is allowed to see the record. It ends up doing the same thing, but you start at the other end.

```ruby
class Post < ApplicationRecord
  belongs_to :blog
  has_many :comments
    
  regulate_broadcast do |policy|
    # Public posts go to everyone
    policy.send_all unless draft?
    # Draft posts go to their owner - 
    # simply traverse up the relations to User
    policy.send_all.to(blog.user)
  end
end

```

You may have to do `send_all.to(Application)` but I feel like that should be the default. The broadcast API could be cleaned up a bit.

```ruby
class BlogComponent < ApplicationComponent
    param :blog_id
    
    render(DIV) do
        H1 { blog.title }
        blog.posts.each do |post|
            H2 { post.title }
        end
    end
    
    def blog
        Blog.find(params.blog_id)
    end
end
```

Actually I think this example won't work as I have it. When one of the posts being fetched is a draft that will cause an AccessViolation error, which is assume will cause the whole fetch to fail. 

So you'd need to do a check in the component and go through a `not_draft` scope as needed. Being able to access policies on the client would help here.

Also there needs to be a route to mount the component. I don't think there's a way to use a Rails route to pass a param to a component—the blog_id above. So I think you'd have to use ReactRouter with a wildcard. It would be a nice simplification if you could pass Rails route params into a component without a ReactRouter.

## CRUD: Save

Our blog has anonymous comments so we want anyone to be able to save a comment and see a comment. 

```ruby
class Comment < ApplicationRecord
  belongs_to :post
    
  # Anyone can save a comment
  allow_create { true }
  # And we want anyone to read comment too
  regulate_broadcast(&:send_all)
end
```

But what if we want comments to be more like a contact form, anyone can save a comment but only the blog owner can see them? Easy change like before:

 ```ruby
class Comment < ApplicationRecord
  belongs_to :post
    
  # Anyone can save a comment
  allow_create { true }
  # Only the blog owner can read comments
  regulate_broadcast do |policy|
      policy.send_all.to(post.blog.user)
  end
end
 ```



## CRUD: Update

Only the person who wrote a blog post should be able to update it. 

### Rails

In Rails you'd check a user is signed in with a before_action, then check they're the right user in the update action. Some boilerplate.

```ruby
class PostsController < ApplicationController
  before_action :authenticate_user, only: [:update, :destroy]

  def update
    @post = Post.find(params[:id])
    if @post.blog.user != current_user
        flash[:error] = "Permission denied"
        redirect_to root_path
        return # important, redirect doesn't return!
    end
    if @post.update(update_params)
        redirect_to post_path(@post)
    else
        render :edit # validation errors
    end
  end
    
  private
    
  def update_params
      params.require(:post).permit(:title, :body)
  end
end
```



### Hyperloop

```ruby
class Post < ApplicationRecord
  # ... same as above ...
    
  # Only the blog owner can update posts
  allow_update { blog.user }
end
```

Speaks for itself really. One line.



## CRUD: Destroy

It's a government blog so accountability is key. Nobody can delete their posts!

```ruby
class Post < ApplicationRecord
  # ... same as above ...
    
  # Nobody can delete posts, accountability!
  allow_destroy { false }
end
```

Requirements change! Okay, now government admins can delete posts on any blog. Note this time we're not traversing an association to get to the blog's owner, we just check the current `acting_user` to see if they're an admin.

```ruby
class Post < ApplicationRecord
  # ... same as above ...
    
  # Admins can destroy any post
  allow_destroy { acting_user.admin? }
end
```

The above would crash if nobody is signed in because `acting_user` would be nil, which has no `admin?` method. But this is actually fine, the delete would fail which is what we want. No need to code defensively to give nice error messages to hackers.