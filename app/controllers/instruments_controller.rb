class InstrumentsController < ImportableController
  include Importers::Controller
  include Exporters

  has_importers({
                  qvmapping: ImportJob::Mapping,
                  topicq: ImportJob::TopicQ
  })
  only_set_object { %i{copy clear_cache response_domains response_domain_codes reorder_ccs stats export mapper mapping member_imports variables} }

  #skip_before_action :authenticate_user!, only: [:latest_document, :mapping]

  @model_class = ::Instrument
  @params_list = %i{agency version prefix label study files import_question_grids}
  @model_importer_class = ImportJob::Instrument

  def index
    @qv_counts = QvMapping.group(:instrument_id).count
    super
  end

  def show
    respond_to do |f|
      f.json {render json: @object}
      f.xml do
        exp = Exporters::XML::DDI::Instrument.new
        exp.add_root_attributes
        filename = exp.run @object
        render file: filename
      end
    end
  end

  def reorder_ccs
    unless params[:updates].nil?
      params[:updates].each do |u|
        unless u[:type].nil? || u[:id].nil? || u[:parent].nil?
          cc = @object.send('cc_'+u[:type].tableize).find(u[:id])
          parent = @object.send('cc_'+u[:parent][:type].tableize).find(u[:parent][:id])
          unless cc.nil? or parent.nil?
            cc.position = u[:position]
            cc.parent = parent
            cc.branch = u[:branch]
            cc.save!
          end
        end
      end
    end
    head :ok, format: :json
  end

  def response_domains
  end

  def response_domain_codes
  end

  def document
    begin
      d = Document.where(item_id: Prefix[params[:id]], item_type: 'Instrument').find(params[:doc_id])
      render body: d.file_contents, content_type: 'application/xml'
    rescue => e
      render xml: {error: 'Not found'}, status: 404
    end
  end

  def latest_document
    d = Document.where(item_id: Prefix[params[:id]], item_type: 'Instrument').order(created_at: :desc).limit(1).first
    if d.nil?
      head :ok
    else
      render body: d.file_contents, content_type: 'application/xml'
    end
  end

  def export
    Resque.enqueue ExportJob::Instrument, @object.id
    head :ok, format: :json
  end

  def variables
    @collection = @object.variables
    render 'variables/index'
  end

  # Destroy action queues a job to destroy an instrument
  def destroy
    begin
      Resque.enqueue DeleteJob::Instrument, @object.id
      head :ok, format: :json
    rescue => e
      logger.fatal 'Failed to destroy instrument'
      logger.fatal e.message
      logger.fatal e.backtrace
      render json: {message: e}, status: :bad_request
    end
  end

  # Used by importing the TXT instrument files that mapper used
  # Please note that for multiple upload to work within a nested
  # Angular 1.X form, base64 encoding was needed so we need to
  # decode the file here as well
  def member_imports
    imports = params[:imports].nil? ? [] : params[:imports]
    head :ok, format: :json if imports.empty?
    #
    # binding.pry
    # 1
    begin
      imports.each do |import|
        doc = Document.new file: Base64.decode64(import[:file])
        doc.save_or_get

        type = import[:type]&.downcase&.to_sym

        Resque.enqueue(@@map[type], doc.id, {object: params[:id]})
      end
      head :ok, format: :json
    rescue  => e
      render json: {message: e}, status: :bad_request
    end
  end

  def clear_cache
    @object.clear_cache
    head :ok
  end

  def copy
    new_details = params.select do |k|
      %w(new_label new_agency new_version new_study).include? k.to_s
    end.to_h.map do |k, v|
      [k.gsub('new_',''), v]
    end
    new_prefix = params['new_prefix']

    begin
      Resque.enqueue CopyJob, @object.id, new_prefix, new_details
      head :ok, format: :json
    rescue => e
      render json: {message: e}, status: :internal_server_error
    end
  end

  def stats
    render json: {stats: @object.association_stats, prefix: @object.prefix}
  end

  def mapping
    respond_to do |format|
      format.text { render 'mapping.txt.erb', layout: false, content_type: 'text/plain' }
      format.json  {}
    end
  end

  private
  def set_object
    @object = collection.find(::Prefix[params[:id]])
  end
end
