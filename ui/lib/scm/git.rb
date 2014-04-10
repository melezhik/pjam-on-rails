class SCM::Git < Struct.new( :component )

    def last_revision
    end

    def check_repository_cmd
    end

    def changes_cmd revision
    end

    def checkout_cmd path
    end

end

