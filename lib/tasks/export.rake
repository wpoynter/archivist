namespace :export do

  desc 'Export all updated instruments'
  task instruments: :environment do
    Instrument.find_each do |i|
      begin
        next if i.last_edited_time.nil?
        if i.export_time.nil? || Date.parse(i.export_time.to_s) < Date.parse(i.last_edited_time.to_s)
          exp = Exporters::XML::DDI::Instrument.new
          exp.add_root_attributes
          exp.export_instrument i

          exp.build_rp
          exp.build_iis
          exp.build_cs
          exp.build_cls
          exp.build_qis
          exp.build_qgs
          exp.build_is
          exp.build_ccs

          d = Document.new
          d.filename = i.prefix + '.xml'
          d.content_type = 'text/xml'
          d.file_contents = exp.doc.to_xml(&:no_empty_tags)
          d.md5_hash = Digest::MD5.hexdigest d.file_contents
          d.save!
          i.add_export_document d
        end
      rescue => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace
      end
    end
  end
end
