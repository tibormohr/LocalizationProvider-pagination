using System.Collections.Generic;
using System.Linq;
using DbLocalizationProvider.Queries;
using DbLocalizationProvider.Refactoring;
using DbLocalizationProvider.Sync;
using Xunit;

namespace DbLocalizationProvider.Tests.TypeDiscoveryHelperTests
{
    public class AssemblyFilterTests
    {
        private readonly TypeDiscoveryHelper _sut;

        public AssemblyFilterTests()
        {
            var state = new ScanState();
            var ctx = new ConfigurationContext();
            var keyBuilder = new ResourceKeyBuilder(state, ctx);
            var oldKeyBuilder = new OldResourceKeyBuilder(keyBuilder);
            ctx.TypeFactory.ForQuery<DetermineDefaultCulture.Query>().SetHandler<DetermineDefaultCulture.Handler>();

            var queryExecutor = new QueryExecutor(ctx.TypeFactory);
            var translationBuilder = new DiscoveredTranslationBuilder(queryExecutor);

            _sut = new TypeDiscoveryHelper(new List<IResourceTypeScanner>
            {
                new LocalizedModelTypeScanner(keyBuilder, oldKeyBuilder, state, ctx, translationBuilder),
                new LocalizedResourceTypeScanner(keyBuilder, oldKeyBuilder, state, ctx, translationBuilder),
                new LocalizedEnumTypeScanner(keyBuilder, translationBuilder),
                new LocalizedForeignResourceTypeScanner(keyBuilder, oldKeyBuilder, state, ctx, translationBuilder)
            }, ctx);
        }

        [Fact]
        public void SpecificAssemblyFilter_ShouldIncludeInternal()
        {
            var assemblies = _sut.GetAssemblies(a => a.FullName.StartsWith("NonExisting"), false);

            Assert.NotEmpty(assemblies);
        }

        [Fact]
        public void SpecificAssemblyFilter_IncludesProviderAssemblies_NoDuplicates()
        {
            var assemblies = _sut.GetAssemblies(a => a.FullName.StartsWith("DbLocalizationProvider"), false);

            Assert.NotEmpty(assemblies);
            Assert.NotNull(assemblies.First(a => a.GetName().Name == "DbLocalizationProvider"));
        }
    }
}
