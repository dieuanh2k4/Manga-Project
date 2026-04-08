using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using backend.src.Services.Entitlements;

namespace backend.src.Services.helper
{
    public static class EntilmentHelper
    {
        // bỏ dấu tiếng việt để chuẩn hóa text 
        public static string RemoveDiacritics(string input)
        {
            var normalizedString = input.Normalize(NormalizationForm.FormD);
            var stringBuilder = new StringBuilder(normalizedString.Length);

            foreach (var c in normalizedString)
            {
                var unicodeCategory = CharUnicodeInfo.GetUnicodeCategory(c);
                if (unicodeCategory != UnicodeCategory.NonSpacingMark)
                {
                    stringBuilder.Append(c);
                }
            }

            return stringBuilder.ToString().Normalize(NormalizationForm.FormC);
        }

        // map các alias về chuẩn dạng key chuẩn
        public static string CanonicalizeFeatureKey(string key)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                return string.Empty;
            }

            return key switch
            {
                "PREMIUM" => EntitlementFeatureKeys.ReadPremium,
                "READ_PREMIUM_CHAPTER" => EntitlementFeatureKeys.ReadPremium,
                "READ_CHAPTER_PREMIUM" => EntitlementFeatureKeys.ReadPremium,
                "DOC_CHUONG_PREMIUM" => EntitlementFeatureKeys.ReadPremium,
                _ => key
            };
        }

        // Uppercase, thay ký tự không phải chữ/số thành dấu gạch dưới
        public static string NormalizeFeatureKey(string rawKey)
        {
            var cleaned = RemoveDiacritics(rawKey).ToUpperInvariant();
            var builder = new StringBuilder(cleaned.Length);
            var previousUnderscore = false;

            foreach (var ch in cleaned)
            {
                if (char.IsLetterOrDigit(ch))
                {
                    builder.Append(ch);
                    previousUnderscore = false;
                    continue;
                }

                if (!previousUnderscore)
                {
                    builder.Append('_');
                    previousUnderscore = true;
                }
            }

            return builder.ToString().Trim('_');
        }
        
        // parse nội dung privilege từ DB thành cặp key-value
        public static (string Key, string Value) ParseFeature(string? rawContent)
        {
            if (string.IsNullOrWhiteSpace(rawContent))
            {
                return (string.Empty, string.Empty);
            }

            var cleaned = RemoveDiacritics(rawContent).Trim();
            var separatorIndex = cleaned.IndexOf('=');
            if (separatorIndex < 0)
            {
                separatorIndex = cleaned.IndexOf(':');
            }

            string keyPart;
            string valuePart;

            if (separatorIndex < 0)
            {
                keyPart = cleaned;
                valuePart = "true";
            }
            else
            {
                keyPart = cleaned[..separatorIndex];
                valuePart = cleaned[(separatorIndex + 1)..];
            }

            var key = CanonicalizeFeatureKey(NormalizeFeatureKey(keyPart));
            var value = string.IsNullOrWhiteSpace(valuePart) ? "true" : valuePart.Trim();

            return (key, value);
        }

        // gộp các quyền khi user có nhiều package
        public static void MergeFeature(Dictionary<string, string> features, string key, string value)
        {
            if (!features.TryGetValue(key, out var existingValue))
            {
                features[key] = value;
                return;
            }

            if (TryParseBool(existingValue, out var existingBool) && TryParseBool(value, out var nextBool))
            {
                features[key] = (existingBool || nextBool).ToString().ToLowerInvariant();
                return;
            }

            if (int.TryParse(existingValue, NumberStyles.Integer, CultureInfo.InvariantCulture, out var existingInt)
                && int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var nextInt))
            {
                features[key] = Math.Max(existingInt, nextInt).ToString(CultureInfo.InvariantCulture);
            }
        }
        
        // đổi chuỗi về boolean linh hoạt
        public static bool TryParseBool(string value, out bool parsed)
        {
            if (bool.TryParse(value, out parsed))
            {
                return true;
            }

            var normalized = value.Trim().ToLowerInvariant();
            if (normalized is "1" or "y" or "yes" or "on" or "enabled")
            {
                parsed = true;
                return true;
            }

            if (normalized is "0" or "n" or "no" or "off" or "disabled")
            {
                parsed = false;
                return true;
            }

            return false;
        }
        public static bool IsTruthy(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return false;
            }

            if (TryParseBool(value, out var boolValue))
            {
                return boolValue;
            }

            if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var intValue))
            {
                return intValue > 0;
            }

            var normalized = value.Trim().ToLowerInvariant();
            return normalized is "y" or "yes" or "on" or "enabled";
        }
        
        // kiểm tra riêng key READ_PREMIUM trong features
        public static bool HasReadPremium(Dictionary<string, string> features)
        {
            if (!features.TryGetValue(EntitlementFeatureKeys.ReadPremium, out var value))
            {
                return false;
            }

            return IsTruthy(value);
        }

        // so sánh key có phải premium hay không
        public static bool IsReadPremiumFeature(string key)
        {
            return string.Equals(key, EntitlementFeatureKeys.ReadPremium, StringComparison.OrdinalIgnoreCase);
        }
    }
}