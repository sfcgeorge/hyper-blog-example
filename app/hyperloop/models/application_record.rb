class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  unless RUBY_ENGINE == "opal"
    regulate_scope all: :always_allow
    regulate_scope unscoped: :always_allow
  end
end
