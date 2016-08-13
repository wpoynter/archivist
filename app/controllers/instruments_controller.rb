class InstrumentsController < ApplicationController
  include BaseController

  add_basic_actions require: ':instrument',
                    params: '[:agency, :version, :prefix, :label, :study, :files]',
                    collection: 'policy_scope(Instrument.all)',
                    only: [:copy, :response_domains, :response_domain_codes, :reorder_ccs, :stats]

  def show
    respond_to do |f|
      f.json {render json: @object}
      f.xml do
        exp = XML::DDI::Exporter.new
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
          cc = @object.send(u[:type] + 's').find(u[:id])
          parent = @object.send(u[:parent][:type] + 's').find(u[:parent][:id])
          unless cc.nil? or parent.nil?
            cc.position = u[:position]
            cc.parent = parent
            cc.branch = u[:branch]
            cc.cc.save!
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

  def import
    FileUtils.mkdir_p Rails.root.join('tmp', 'uploads')
    files = params[:files].nil? ? [] : params[:files]
    head :ok, format: :json if files.empty?
    files.each do |file|
      filepath = Rails.root.join(
          'tmp',
          'uploads',
          (0...8).map { (65 + rand(26)).chr }.join + '-' + file.original_filename
      )
      File.open(filepath, 'wb') do |f|
        f.write(file.read)
      end
      begin
        Resque.enqueue Import, filepath[:path]
        head :ok, format: :json
      rescue  => e
        render json: {message: e}, status: :bad_request
      end
    end
  end

  def copy
    new_details = params.select {
        |k, v| ['new_prefix', 'new_label', 'new_agency', 'new_version', 'new_study'].include? k.to_s
    }
    new_instrument = @object.copy new_details
    head :ok, format: :json
  end

  def stats
    render json: @object.association_stats
  end
end