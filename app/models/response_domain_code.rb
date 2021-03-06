# The ResponseDomainCode is based on the CodeDomain model from DDI3.X and serves as creates a
# response domain for a {CodeList}
#
# Using the min_responses and max_responses properties cardinality can be recorded.
#
# Please visit http://www.ddialliance.org/Specification/DDI-Lifecycle/3.2/XMLSchema/FieldLevelDocumentation/schemas/datacollection_xsd/elements/CodeDomain.html
#
# === Properties
# * Min Responses
# * Max Responses
class ResponseDomainCode < ApplicationRecord
  # This model has all the standard {ResponseDomain} features from DDI3.X
  include ResponseDomain

  # All ResponseDomainCodes must belong to a {CodeList}
  belongs_to :code_list

  # Before creating a ResponseDomainCode in the database ensure the instrument has been set
  before_create :set_instrument

  # RDCs do not have their own label, so it is delagated to the {CodeList} it belongs to
  delegate :label, to: :code_list

  # Returns basic information on the response domain's codes
  #
  # @return [Array] List of codes as hashes
  def codes
    self.code_list.codes.map do |x|
      {
          label: x.category.label,
          value: x.value,
          order: x.order
      }
    end
  end

  private  # private methods
  # Sets instrument_id from the {CodeList} that this ResponseDomainCode belongs to
  def set_instrument
    self.instrument_id = code_list.instrument_id
  end
end
