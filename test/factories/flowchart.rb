Factory.define(:flowchart, class: Flowchart) do |f|
    f.study_id { Factory.create(:study).id }
    f.source_sample_type_id '1'
    f.after_build do |flowchart|
        id = Factory.create(:assay,study: flowchart.study, assay_assets: [Factory.create(:assay_asset, asset:Factory.create(:sop))]).id
        flowchart.items = JSON.generate([{ id: '', left: '1', top: '1' },{ id: id.to_s, left: '10', top: '10' }])
    end
end