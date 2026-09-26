class ErrorsController < ActionController::API
  def not_found
    render json: json_error("404.json"), status: :not_found
  end

  def unprocessable_entity
    render json: json_error("422.json"), status: :unprocessable_content
  end

  def internal_server_error
    render json: json_error("500.json"), status: :internal_server_error
  end

  private

  def json_error(filename)
    JSON.parse(Rails.public_path.join(filename).read)
  end
end
