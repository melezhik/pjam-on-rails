class ActivitiesController < ApplicationController

    def show
        @history = History.limit(50).order( id: :desc )
    end
end
