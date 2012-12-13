require_dependency 'user'

class GollumController < ApplicationController
  unloadable

  before_filter :find_project, :find_wiki, :authorize

  def index
    redirect_to :action => :show, :id => "Home"
  end

  def show
    @editable = true
    fullname     = params[:id]
    name         = extract_name(fullname)
    path         = extract_path(fullname) || ''

    if page = @wiki.page(name)
      if path.empty?
        redirect_to :action => :show, :id => page.url_path
      end
         
      @page_name = page.name
      @page_title = page.title
      @page_content = page.formatted_data.html_safe 
      if page.toc_data
	      @page_toc = page.toc_data.html_safe
      end
      create_wiki_index()
    elsif file = @wiki.file(fullname)
      send_data file.raw_data, :type => file.mime_type, :disposition => 'inline'
    else
      redirect_to :action => :edit, :id => name
      create_wiki_index()
    end
    
  end

  def edit
    @name = params[:id]
    @page = @wiki.page(@name)
    @content = @page ? @page.text_data : ""
    create_wiki_index()
  end

  def update
    @name = params[:id]
    @page = @wiki.page(@name)
    @user = User.current

    commit = { :message => params[:page][:message], :name => @user.name, :email => @user.mail }

    if @page
      @wiki.update_page(@page, @page.name, @page.format, params[:page][:raw_data], commit)
    else
      @wiki.write_page(@name, @project.gollum_wiki.markup_language.to_sym, params[:page][:raw_data], commit)
    end

    redirect_to :action => :show, :id => @name
  end

  private

  def project_repository_path
    return @project.gollum_wiki.git_path
  end


  def create_wiki_index()
      pages = @wiki.pages
      count = pages.size
      pages_li = ''
      count.times do | index |
        page = pages[ index ]
        pages_li += '<li><a href="/projects/' + params[:project_id] + "/gollum/" + page.url_path + '">' + page.url_path + '</a></li>';
      end
      @page_index = ('<ul id="pages">' + pages_li + '</ul>').html_safe
  end
     
  def find_project
    unless params[:project_id].present?
      render :status => 404
      return
    end

    @project = Project.find(params[:project_id])
  end

  def find_wiki
    git_path = project_repository_path

    unless File.directory? git_path
      Grit::Repo.init_bare(git_path)
    end

    wiki_dir = @project.gollum_wiki.directory
    if wiki_dir.empty?
      wiki_dir = nil
    end

    gollum_base_path = project_gollum_index_path
    @wiki = Gollum::Wiki.new(git_path,
                            :base_path => gollum_base_path,
                            :page_file_dir => wiki_dir)

  end

  def extract_path(file_path)
    return nil if file_path.nil?
    last_slash = file_path.rindex("/")
    if last_slash
      file_path[0, last_slash]
    end
  end

  # Extract the 'page' name from the file_path
  def extract_name(file_path)
    ::File.basename(file_path)
  end

end
