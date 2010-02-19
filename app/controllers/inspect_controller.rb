class InspectController < ApplicationController
  def question
    @q = Question.find(params[:id])
    @page_title = "$#{@q.value} | #{@q.category.name}"
    @body_id = "question"
    @no_script = true
  end
end
