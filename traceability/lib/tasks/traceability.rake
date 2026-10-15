namespace :traceability do
  desc "Index the section 9 chain from the repository JSON into SQLite"
  task load: :environment do
    record = TraceabilityIndex.load!
    generation = SdkContract.find_by!(external_id: "SDK-Generation")
    release = SdkRelease.find_by!(external_id: generation.release_ids.sole)
    puts "status=#{record.status}"
    puts "acceptance=#{release.acceptance}"
    puts "sdk_generation_vector_links=#{generation.reference_vector_ids.size}"
  end
end
