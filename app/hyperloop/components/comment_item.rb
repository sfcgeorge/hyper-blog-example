class CommentItem < Hyperloop::Component
  param :comment

  render(DIV) do
    SMALL(style: { float: "right" }) { params.comment.created_at.to_s }
    H5 { params.comment.body.to_s }
    HR()
  end
end
