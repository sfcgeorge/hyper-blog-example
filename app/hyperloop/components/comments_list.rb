class CommentsList < Hyperloop::Component
  param :post_id

  state(:comment) { new_comment }

  render(DIV) do
    post.comments.each do |comment|
      CommentItem(comment: comment, key: comment)
    end
    CommentEditor(
      comment: state.comment,
    ).on(:save) { mutate.comment new_comment }
  end

  def post
    Post.find(params.post_id)
  end

  def new_comment
    Comment.new(post: post)
  end
end
