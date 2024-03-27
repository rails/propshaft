class Propshaft::DependencyTree

  def initialize(compilers:)
    @compilers = compilers
  end

  # a single pass through the dependent assets, calculating all the dependency
  # fingerprints we can.
  def dependency_fingerprint_pass(mapped, dependent_assets)
    dependent_assets.each do |asset|
      # the fingerprint can be calculated unless a dependency of this asset
      # is not ready yet.
      next if asset.dependencies.detect{|da| da.digest_too_soon?}
      # ok, ready to set the fingerprint, which is the concatenation of the
      # digests of each dependent asset.
      # the fingerprints need to maintain a stable order, done via the sort.
      asset.dependency_fingerprint = asset.dependencies.map(&:digest).sort.join
    end
    # clear out any ones we are done with.
    dependent_assets.delete_if{|asset| asset.dependency_fingerprint.present?}
  end

  # After we know the assets that depend on other propshaft assets, we can iterate
  # through the list, calculating the dependency fingerprint for any asset with
  # children with known digests.  Once we run out of dependent assets without
  # digests, we are done.  But if we notice that we aren't making any progress on
  # an iteration, it means there is an asset dependency cycle.  In that case we
  # bail out and warn.
  def set_dependency_fingerprints(mapped, dependent_assets)
    # There will be N iterations where N is the depth of the longest dependency chain.
    loop do
      initial_count = dependent_assets.size
      dependency_fingerprint_pass(mapped, dependent_assets)
      break if dependent_assets.empty?    # success, all done
      if dependent_assets.size == initial_count
        # failing to make progress
        cyclic_assets = dependent_assets.map{|a| a.logical_path.to_s}.join(', ')
        Propshaft.logger.warn "Dependency cycle between #{cyclic_assets}"
        break
      end
    end
  end

  def traverse(mapped)
    dependent_assets = Set.new
    mapped.each_pair do |path, asset|
      next unless asset.may_depend?     # skip static asset types
      # get logical paths of dependencies
      deps = @compilers.find_dependencies(asset)
      # convert logical paths to asset objects
      # asset references that aren't managed by propshaft will not be in the mapping
      # and can be ignored since they won't have digests
      asset.dependencies = deps.map{|d| mapped[d]}.compact
      # If no dependencies, the normal digest will be fine for this asset.
      # Otherwise we will need to perform dependency tree traversal to
      # create dependency-aware digests. Keep a list of such assets to visit.
      dependent_assets << asset if asset.dependencies.any?
    end
    set_dependency_fingerprints(mapped, dependent_assets)
  end
end
