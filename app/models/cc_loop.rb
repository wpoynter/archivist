class CcLoop < ActiveRecord::Base
  include Construct::Model
  is_a_parent

  URN_TYPE = 'lp'
  TYPE = 'Loop'

  def self.create_with_position(params)
    obj = new()
    i = Instrument.find(params[:instrument_id])
    i.send('cc_' + params[:type].pluralize) << obj

    parent = i.send('cc_' + params[:parent][:type].pluralize).find(params[:parent][:id])
    unless parent.nil?
      if parent.has_children?
        obj.position = parent.last_child.position + 1
      else
        obj.position = 1
      end

      unless params[:branch].nil?
        obj.branch = params[:branch]
      end
    end
    obj.label = params[:label]
    obj.end_val = params[:end_val]
    obj.loop_var = params[:loop_var]
    obj.loop_while = params[:loop_while]
    obj.start_val = params[:start_val]
    parent.children << obj.cc
    obj.save!
    obj
  end
end
