class ConstructController < BasicInstrumentController
  def create
    begin
      @object = collection.create(safe_params)
      if @object
        render :show, status: :created
      else
        render json: @object.errors, status: :unprocessable_entity
      end
    rescue => e
      response = {error: e}
      render json: response, status: :internal_server_error
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def safe_params
    obj_name = self.class.model_class.name.underscore.to_sym
    params = wrap_parent_param(self.params, obj_name)
    params[obj_name] = shim_construct_type(params[obj_name])
    params.require( obj_name )
        .permit( [:label, :parent_id, :parent_type, :position, :branch, :instrument_id]  + self.class.params_list )
  end

  private
  def shim_construct_type(p)
    unless p[:parent_type].nil?
      p[:parent_type] = case p[:parent_type].downcase
                          when 'condition' then
                            'CcCondition'
                          when 'loop' then
                            'CcLoop'
                          when 'question' then
                            'CcQuestion'
                          when 'sequence' then
                            'CcSequence'
                          when 'statement' then
                            'CcStatement'
                        end
    end
    p
  end

  def wrap_parent_param(p, obj_name)
    if p.has_key? :parent
      p[obj_name][:parent_id] = p[:parent][:id]
      p[obj_name][:parent_type] = p[:parent][:type]
      p.delete(:parent)
    end
    p
  end
end