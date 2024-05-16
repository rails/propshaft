module ApplicationHelper
  def app_stylesheets?
    params[:stylesheets] == "app"
  end
end
