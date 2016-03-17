class RecentsController < ApplicationController
  before_action :set_recent, only: [:show, :destroy]

  def index
    @recent = Recent.new
    @recents = Recent.all
  end

  def show
    check_timestamp()
    @profile_cards = @recent.handles[:good]
    @bad_handles = @recent.handles[:bad]
  end

  def create
    @recent = Recent.new(recent_params)
    @existing = Recent.check_by_hash(@recent.url_string)
    
    if @existing 
      redirect_to @existing, notice: 'Url was successfully parsed before.'
    elsif @recent.save
      redirect_to @recent, notice: 'Url was successfully added.'
    else
      render :new
    end
  end

  def destroy
    @recent.destroy
    redirect_to recents_url, notice: 'Url was successfully destroyed.'
  end

  private
    def set_recent
      @recent = Recent.find(params[:id])
    end

    # whitelist parameters
    def recent_params
      params.require(:recent).permit(:url_string)
    end

    # update it if it's more than 5 mins ago
    def check_timestamp
      @recent.save! if Time.now - @recent.updated_at >= 600
    end
end
