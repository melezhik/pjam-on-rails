class BuildAsync
    def perform
        system("touch /tmp/hello300.txt")
    end
end
