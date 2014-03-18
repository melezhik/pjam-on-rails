require 'redcarpet'
class WelcomeController < ApplicationController
  def index
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true, filter_html: true)
    options = {
        autolink: true,
        no_intra_emphasis: true,
        fenced_code_blocks: true,
        lax_html_blocks: true,
        strikethrough: true,
        superscript: true,
        space_after_headers: true
    }

    @text = Redcarpet::Markdown.new(renderer, options).render(File.read("#{Rails.public_path}/../../README.md")).html_safe    
  end
end
