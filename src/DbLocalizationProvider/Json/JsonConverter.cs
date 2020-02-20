// Copyright (c) Valdis Iljuconoks. All rights reserved.
// Licensed under Apache-2.0. See the LICENSE file in the project root for more information

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using DbLocalizationProvider.Queries;
using Newtonsoft.Json.Linq;

namespace DbLocalizationProvider.Json
{
    /// <summary>
    /// Class used in various clientside localization resource provider operations
    /// </summary>
    public class JsonConverter
    {
        /// <summary>
        /// Gets the JSON object from given resource class.
        /// </summary>
        /// <param name="resourceClassName">Name of the resource class.</param>
        /// <param name="camelCase">if set to <c>true</c> JSON properties will be in camelCase; otherwise PascalCase is used.</param>
        /// <returns>JSON object that represents resource</returns>
        public JObject GetJson(string resourceClassName, bool camelCase = false)
        {
            return GetJson(resourceClassName, CultureInfo.CurrentUICulture.Name, camelCase);
        }

        /// <summary>
        /// Gets the JSON object from given resource class.
        /// </summary>
        /// <param name="resourceClassName">Name of the resource class.</param>
        /// <param name="languageName">Name of the language.</param>
        /// <param name="camelCase">if set to <c>true</c> JSON properties will be in camelCase; otherwise PascalCase is used.</param>
        /// <returns>JSON object that represents resource</returns>
        public JObject GetJson(string resourceClassName, string languageName, bool camelCase = false)
        {
            var resources = new GetAllResources.Query().Execute();
            var filteredResources = resources.Where(r => r.ResourceKey.StartsWith(resourceClassName, StringComparison.InvariantCultureIgnoreCase)).ToList();

            return Convert(filteredResources, languageName, ConfigurationContext.Current.EnableInvariantCultureFallback, camelCase);
        }

        internal JObject Convert(ICollection<LocalizationResource> resources, string language, bool invariantCultureFallback, bool camelCase)
        {
            var result = new JObject();

            foreach (var resource in resources)
            {
                // we need to process key names and supported nested classes with "+" symbols in keys -> so we replace those with dots to have proper object nesting on client side
                var key = resource.ResourceKey.Replace("+", ".");
                if (!key.Contains(".")) continue;

                if (!resource.Translations.ExistsLanguage(language) && !invariantCultureFallback) continue;

                var segments = key.Split(new[] { "." }, StringSplitOptions.None).Select(k => camelCase ? CamelCase(k) : k).ToList();
                var translation = resource.Translations.ByLanguage(language, invariantCultureFallback);

                Aggregate(result,
                          segments,
                          (e, segment) =>
                          {
                              if (e[segment] == null)
                                  e[segment] = new JObject();

                              return e[segment] as JObject;
                          },
                          (o, s) => { o[s] = translation; });
            }

            return result;
        }

        private static void Aggregate(JObject seed, ICollection<string> segments, Func<JObject, string, JObject> act, Action<JObject, string> last)
        {
            if (segments == null || !segments.Any()) return;

            var lastElement = segments.Last();
            var seqWithNoLast = segments.Take(segments.Count - 1);
            var s = seqWithNoLast.Aggregate(seed, act);

            last(s, lastElement);
        }

        private static string CamelCase(string that)
        {
            if (that.Length > 1) return that.Substring(0, 1).ToLower() + that.Substring(1);

            return that.ToLower();
        }
    }
}
