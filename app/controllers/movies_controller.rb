class MoviesController < ApplicationController
  wrap_parameters false
  
  def index
    movies = Movie.all
    render json: movies
  end

  def create
    movie = Movie.create!(movie_params)
    render json: movie, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def movie_params
    params.permit(:title, :year, :length, :director, :description, :poster_url, :category, :discount, :female_director)
  end
  
end
