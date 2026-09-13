module Admin
  class MatchPlayersController < BaseController
    before_action :set_match
    before_action :set_match_player, only: :destroy

    def create
      @match_player = @match.match_players.build(match_player_params)
      @match_player.status ||= :confirmed

      if @match_player.save
        redirect_to redirect_path, notice: "Player was successfully added to the match."
      else
        redirect_to redirect_path, alert: @match_player.errors.full_messages.to_sentence
      end
    end

    def destroy
      if @match_player.destroy
        redirect_to redirect_path, notice: "Player was successfully removed from the match."
      else
        redirect_to redirect_path, alert: @match_player.errors.full_messages.to_sentence
      end
    end

    private

    def set_match
      @match = Match.find(params[:match_id])
    end

    def set_match_player
      @match_player = @match.match_players.find(params[:id])
    end

    def match_player_params
      params.require(:match_player).permit(:user_id, :team, :status)
    end

    def redirect_path
      params[:return_to] == "show" ? admin_match_path(@match) : edit_admin_match_path(@match)
    end
  end
end
