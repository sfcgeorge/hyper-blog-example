class CommentEditor < Hyperloop::Component
  param :comment
  param :on_save, type: Proc

  render(DIV) do
    INPUT(defaultValue: params.comment.body).on(:key_down) do |e|
      next unless e.key_code == 13
      params.comment.update(body: e.target.value)
      params.on_save
    end
  end
end
