module XML::Sledgehammer
  class Importer
    def initialize(thing, options = {})
      if thing.is_a? String
        @doc = open(thing) { |f| Nokogiri::XML(f) }
      else
        @document = Document.find thing
        @doc = Nokogiri::XML document.file_contents
      end
      @counters = {}
    end

    def parse
      @dataset = Importer.build_dataset( @doc, filename: File.basename(@filepath))
      unless @document.nil?
        @document.item = @datset
      end
      read_variables
    end

    def read_variables
      vars = @doc.xpath "//ddi:Variable"
      vars.each do |var|
        v = Variable.new
        v.name = var.at_xpath("./ddi:VariableName/r:String").content
        v.label = var.at_xpath("./r:Label/r:Content").content
        v.var_type = 'Normal'
        @dataset.variables << v
      end
    end

    def self.build_dataset(doc, options = {})
      d = Dataset.new
      d.name = doc.at_xpath("//pi:PhysicalInstance/r:Citation/r:Title/r:String").content
      d.doi = doc.at_xpath("//pi:DataFileURI").content
      d.filename = options[:filename] unless options[:filename].nil?
      d.save!
      d
    end
  end
end