class GroupsController < ApplicationController
  before_action :set_group, only: [:show, :edit, :update, :destroy, :join, :leave]

  def show
    @group = Group.includes(:users).find(params[:id])
    @current_user_in_group = @group.users.include? current_user

    if @current_user_in_group
      books = Book.joins(read_records: {user: :groups})
                   .where(groups: {id: @group.id}, read_records:{status: "read"})
                   .distinct

      @book_infos = books.map do |book|
          {
            i_read: book.read_records.map(&:user).include?(current_user),
            book_url: book.url,
            title: book.title,
            read_num: book.read_records.size,
            read_people: book.read_records.map do |read_record|
              {
                  douban_link: "http://book.douban.com/people/#{read_record.user.douban_auth_info.douban_user_id}/",
                  name: read_record.user.douban_auth_info.douban_user_name
              }
            end
        }
      end
      .sort_by{|item| item[:read_num]}
      .reverse
    end
  end

  # GET /groups/new
  def new
    @group = Group.new
  end

  # GET /groups/1/edit
  def edit
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = Group.new(group_params)

    respond_to do |format|
      if @group.save
        format.html { redirect_to @group, notice: 'Group was successfully created.' }
        format.json { render :show, status: :created, location: @group }
      else
        format.html { render :new }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /groups/1
  # PATCH/PUT /groups/1.json
  def update
    respond_to do |format|
      if @group.update(group_params)
        format.html { redirect_to @group, notice: 'Group was successfully updated.' }
        format.json { render :show, status: :ok, location: @group }
      else
        format.html { render :edit }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  def join
    @group.users << current_user
    @group.save
    redirect_to root_path
  end

  def leave
    @group.users.delete(current_user.id)
    redirect_to root_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def group_params
      params[:group].permit(:name, :description)
    end
end
