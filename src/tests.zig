const std = @import("std");
const regex = @import("regex");

// TODO: More testing?

fn expectEqualStrings(expected: []const u8, string: []const u8) !void {
    return std.testing.expectEqualStrings(expected, string);
}

fn expectEqualStringsUnicode(expected: []const u8, string: []const regex.p_wchar) !void {
    const allocator = std.testing.allocator;
    const string_utf8 = try regex.utfWideToUtf8Alloc(allocator, string);
    defer allocator.free(string_utf8);
    try expectEqualStrings(expected, string_utf8);
}

test "Fail" {
    try std.testing.expectError(error.Fail, regex.Regex.compile(std.testing.allocator, "**", null));
}

test "Match" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "a(b+)c", null);
    defer re.deinit();

    if (try re.match("abbbc")) |m| {
        defer m.deinit();
        try expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try expectEqualStrings("bbb", m.groups[1].slice);
        try std.testing.expectEqual(1, m.groups[1].index);
    } else return error.Fail;

    if (try re.match("   abbbc")) |m| {
        m.deinit();
        return error.Fail;
    }
}

test "Match (unicode)" {
    const allocator = std.testing.allocator;
    var re = try regex.WRegex.compile(allocator, "a(🍕+)c", null);
    defer re.deinit();

    const input = try regex.utf8ToUtfWideLeAlloc(allocator, "a🍕🍕🍕c");
    defer allocator.free(input);

    if (try re.match(input)) |m| {
        defer m.deinit();
        try std.testing.expectEqual(2, m.groups.len);

        try expectEqualStringsUnicode("a🍕🍕🍕c", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);

        try expectEqualStringsUnicode("🍕🍕🍕", m.groups[1].slice);
        try std.testing.expectEqual(1, m.groups[1].index);
    } else return error.Fail;
}

test "Workaround Match" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "\\s*(a(b+)c)\\s*", null);
    defer re.deinit();

    if (try re.match("abbbc")) |m| {
        defer m.deinit();
        try expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try expectEqualStrings("abbbc", m.groups[1].slice);
        try std.testing.expectEqual(0, m.groups[1].index);
        try expectEqualStrings("bbb", m.groups[2].slice);
        try std.testing.expectEqual(1, m.groups[2].index);
    } else return error.Fail;

    if (try re.match("   abbbc")) |m| {
        defer m.deinit();
        try expectEqualStrings("   abbbc", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try expectEqualStrings("abbbc", m.groups[1].slice);
        try std.testing.expectEqual(3, m.groups[1].index);
        try expectEqualStrings("bbb", m.groups[2].slice);
        try std.testing.expectEqual(4, m.groups[2].index);
    } else return error.Fail;
}

test "Workaround Match (unicode)" {
    const allocator = std.testing.allocator;
    var re = try regex.WRegex.compile(allocator, "\\s*(a(🍕+)c)\\s*", null);
    defer re.deinit();

    const input = try regex.utf8ToUtfWideLeAlloc(allocator, "a🍕🍕🍕c");
    defer allocator.free(input);
    if (try re.match(input)) |m| {
        defer m.deinit();
        try expectEqualStringsUnicode("a🍕🍕🍕c", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try expectEqualStringsUnicode("a🍕🍕🍕c", m.groups[1].slice);
        try std.testing.expectEqual(0, m.groups[1].index);
        try expectEqualStringsUnicode("🍕🍕🍕", m.groups[2].slice);
        try std.testing.expectEqual(1, m.groups[2].index);
    } else return error.Fail;

    const input2 = try regex.utf8ToUtfWideLeAlloc(allocator, "   a🍕🍕🍕c");
    defer allocator.free(input2);
    if (try re.match(input2)) |m| {
        defer m.deinit();
        try expectEqualStringsUnicode("   a🍕🍕🍕c", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try expectEqualStringsUnicode("a🍕🍕🍕c", m.groups[1].slice);
        try std.testing.expectEqual(3, m.groups[1].index);
        try expectEqualStringsUnicode("🍕🍕🍕", m.groups[2].slice);
        try std.testing.expectEqual(4, m.groups[2].index);
    } else return error.Fail;
}

test "Search" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "a(b+)c", null);
    defer re.deinit();

    if (try re.search("abbbc")) |m| {
        defer m.deinit();
        try expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try expectEqualStrings("bbb", m.groups[1].slice);
        try std.testing.expectEqual(1, m.groups[1].index);
    } else return error.Fail;

    if (try re.search("   abbbc")) |m| {
        defer m.deinit();
        try expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(3, m.groups[0].index);
        try expectEqualStrings("bbb", m.groups[1].slice);
        try std.testing.expectEqual(4, m.groups[1].index);
    }
}

test "Search (unicode)" {
    const allocator = std.testing.allocator;
    var re = try regex.WRegex.compile(allocator, "a(🍕+)c", null);
    defer re.deinit();

    const input = try regex.utf8ToUtfWideLeAlloc(allocator, "a🍕🍕🍕c");
    defer allocator.free(input);
    if (try re.search(input)) |m| {
        defer m.deinit();
        try expectEqualStringsUnicode("a🍕🍕🍕c", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try expectEqualStringsUnicode("🍕🍕🍕", m.groups[1].slice);
        try std.testing.expectEqual(1, m.groups[1].index);
    } else return error.Fail;

    const input2 = try regex.utf8ToUtfWideLeAlloc(allocator, "   a🍕🍕🍕c");
    defer allocator.free(input2);
    if (try re.search(input2)) |m| {
        defer m.deinit();
        try expectEqualStringsUnicode("a🍕🍕🍕c", m.groups[0].slice);
        try std.testing.expectEqual(3, m.groups[0].index);
        try expectEqualStringsUnicode("🍕🍕🍕", m.groups[1].slice);
        try std.testing.expectEqual(4, m.groups[1].index);
    }
}

test "Replace" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "b+", null);
    defer re.deinit();

    const result1 = try re.allocReplace(allocator, "abbbc", "$0");
    defer allocator.free(result1);
    try expectEqualStrings("abbbc", result1);
    const result2 = try re.allocReplace(allocator, "abbbc", "c");
    defer allocator.free(result2);
    try expectEqualStrings("acc", result2);
    const result3 = try re.allocReplace(allocator, "adddc", "c");
    defer allocator.free(result3);
    try expectEqualStrings("adddc", result3);
    const result4 = try re.allocReplace(allocator, "abbbc abbbc", "c");
    defer allocator.free(result4);
    try expectEqualStrings("acc abbbc", result4);
}

fn allocReplaceUnicode(re: *regex.WRegex, allocator: std.mem.Allocator, input: []const u8, replacement: []const u8) ![]const regex.p_wchar {
    const input_utf16 = try regex.utf8ToUtfWideLeAlloc(allocator, input);
    defer allocator.free(input_utf16);
    const replacement_utf16 = try regex.utf8ToUtfWideLeAlloc(allocator, replacement);
    defer allocator.free(replacement_utf16);
    return try re.allocReplace(allocator, input_utf16, replacement_utf16);
}
test "Replace (unicode)" {
    const allocator = std.testing.allocator;
    var re = try regex.WRegex.compile(allocator, "b+", null);
    defer re.deinit();

    const result1 = try allocReplaceUnicode(&re, allocator, "abbbc", "$0");
    defer allocator.free(result1);
    try expectEqualStringsUnicode("abbbc", result1);
    const result2 = try allocReplaceUnicode(&re, allocator, "abbbc", "c");
    defer allocator.free(result2);
    try expectEqualStringsUnicode("acc", result2);
    const result3 = try allocReplaceUnicode(&re, allocator, "adddc", "c");
    defer allocator.free(result3);
    try expectEqualStringsUnicode("adddc", result3);
    const result4 = try allocReplaceUnicode(&re, allocator, "abbbc abbbc", "c");
    defer allocator.free(result4);
    try expectEqualStringsUnicode("acc abbbc", result4);
}

test "ReplaceAll" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "b+", null);
    defer re.deinit();

    const result1 = try re.allocReplaceAll(allocator, "abbbc", "$0");
    defer allocator.free(result1);
    try expectEqualStrings("abbbc", result1);
    const result2 = try re.allocReplaceAll(allocator, "abbbc", "c");
    defer allocator.free(result2);
    try expectEqualStrings("acc", result2);
    const result3 = try re.allocReplaceAll(allocator, "adddc", "c");
    defer allocator.free(result3);
    try expectEqualStrings("adddc", result3);
    const result4 = try re.allocReplaceAll(allocator, "abbbc abbbc", "c");
    defer allocator.free(result4);
    try expectEqualStrings("acc acc", result4);
}

fn allocReplaceAllUnicode(re: *regex.WRegex, allocator: std.mem.Allocator, input: []const u8, replacement: []const u8) ![]const regex.p_wchar {
    const input_utf16 = try regex.utf8ToUtfWideLeAlloc(allocator, input);
    defer allocator.free(input_utf16);
    const replacement_utf16 = try regex.utf8ToUtfWideLeAlloc(allocator, replacement);
    defer allocator.free(replacement_utf16);
    return try re.allocReplaceAll(allocator, input_utf16, replacement_utf16);
}
test "ReplaceAll (unicode)" {
    const allocator = std.testing.allocator;
    var re = try regex.WRegex.compile(allocator, "b+", null);
    defer re.deinit();

    const result1 = try allocReplaceAllUnicode(&re, allocator, "abbbc", "$0");
    defer allocator.free(result1);
    try expectEqualStringsUnicode("abbbc", result1);
    const result2 = try allocReplaceAllUnicode(&re, allocator, "abbbc", "c");
    defer allocator.free(result2);
    try expectEqualStringsUnicode("acc", result2);
    const result3 = try allocReplaceAllUnicode(&re, allocator, "adddc", "c");
    defer allocator.free(result3);
    try expectEqualStringsUnicode("adddc", result3);
    const result4 = try allocReplaceAllUnicode(&re, allocator, "abbbc abbbc", "c");
    defer allocator.free(result4);
    try expectEqualStringsUnicode("acc acc", result4);
}

test "ReplaceAll CaseInsensitive" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "^(a)(b+)(c)$", regex.FLAG_IGNORECASE);
    defer re.deinit();

    const result1 = try re.allocReplaceAll(allocator, "ABBBC", "$0");
    defer allocator.free(result1);
    try expectEqualStrings("ABBBC", result1);
    const result2 = try re.allocReplaceAll(allocator, "ABBBC", "$1c$3");
    defer allocator.free(result2);
    try expectEqualStrings("AcC", result2);
    const result3 = try re.allocReplaceAll(allocator, "ADDDC", "$1c$3");
    defer allocator.free(result3);
    try expectEqualStrings("ADDDC", result3);
    {
        const result4 = try re.allocReplaceAll(allocator, "ABBBC ABBBC", "$1c$3");
        defer allocator.free(result4);
        try expectEqualStrings("ABBBC ABBBC", result4);
        const result5 = try re.allocReplaceAll(allocator, "ABBBC\nABBBC", "$1c$3");
        defer allocator.free(result5);
        try expectEqualStrings("ABBBC\nABBBC", result5);
    }
}

test "ReplaceAll CaseInsensitive (unicode)" {
    const allocator = std.testing.allocator;
    var re = try regex.WRegex.compile(allocator, "^(a)(🍕+)(c)$", regex.FLAG_IGNORECASE);
    defer re.deinit();

    const result1 = try allocReplaceAllUnicode(&re, allocator, "A🍕🍕🍕C", "$0");
    defer allocator.free(result1);
    try expectEqualStringsUnicode("A🍕🍕🍕C", result1);
    const result2 = try allocReplaceAllUnicode(&re, allocator, "A🍕🍕🍕C", "$1c$3");
    defer allocator.free(result2);
    try expectEqualStringsUnicode("AcC", result2);
    const result3 = try allocReplaceAllUnicode(&re, allocator, "ADDDC", "$1c$3");
    defer allocator.free(result3);
    try expectEqualStringsUnicode("ADDDC", result3);
    {
        const result4 = try allocReplaceAllUnicode(&re, allocator, "A🍕🍕🍕C A🍕🍕🍕C", "$1c$3");
        defer allocator.free(result4);
        try expectEqualStringsUnicode("A🍕🍕🍕C A🍕🍕🍕C", result4);
        const result5 = try allocReplaceAllUnicode(&re, allocator, "A🍕🍕🍕C\nA🍕🍕🍕C", "$1c$3");
        defer allocator.free(result5);
        try expectEqualStringsUnicode("A🍕🍕🍕C\nA🍕🍕🍕C", result5);
    }
}

test "ReplaceAll CaseInsensitive Multiline" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "^(a)(b+)(c)$", regex.FLAG_IGNORECASE | regex.FLAG_MULTILINE);
    defer re.deinit();

    const result1 = try re.allocReplaceAll(allocator, "ABBBC\nABBBC", "$0");
    defer allocator.free(result1);
    try expectEqualStrings("ABBBC\nABBBC", result1);
    const result2 = try re.allocReplaceAll(allocator, "ABBBC\nABBBC", "$1c$3");
    defer allocator.free(result2);
    try expectEqualStrings("AcC\nAcC", result2);
    const result3 = try re.allocReplaceAll(allocator, "ADDDC\nADDDC", "$1c$3");
    defer allocator.free(result3);
    try expectEqualStrings("ADDDC\nADDDC", result3);
    const result4 = try re.allocReplaceAll(allocator, "ABBBC ABBBC\nABBBC ABBBC", "$1c$3");
    defer allocator.free(result4);
    try expectEqualStrings("ABBBC ABBBC\nABBBC ABBBC", result4);
}

test "ReplaceAll CaseInsensitive Multiline (unicode)" {
    const allocator = std.testing.allocator;
    var re = try regex.WRegex.compile(allocator, "^(a)(🍕+)(c)$", regex.FLAG_IGNORECASE | regex.FLAG_MULTILINE);
    defer re.deinit();

    const result1 = try allocReplaceAllUnicode(&re, allocator, "A🍕🍕🍕C\nA🍕🍕🍕C", "$0");
    defer allocator.free(result1);
    try expectEqualStringsUnicode("A🍕🍕🍕C\nA🍕🍕🍕C", result1);
    const result2 = try allocReplaceAllUnicode(&re, allocator, "A🍕🍕🍕C\nA🍕🍕🍕C", "$1c$3");
    defer allocator.free(result2);
    try expectEqualStringsUnicode("AcC\nAcC", result2);
    const result3 = try allocReplaceAllUnicode(&re, allocator, "ADDDC\nADDDC", "$1c$3");
    defer allocator.free(result3);
    try expectEqualStringsUnicode("ADDDC\nADDDC", result3);
    const result4 = try allocReplaceAllUnicode(&re, allocator, "A🍕🍕🍕C A🍕🍕🍕C\nA🍕🍕🍕C A🍕🍕🍕C", "$1c$3");
    defer allocator.free(result4);
    try expectEqualStringsUnicode("A🍕🍕🍕C A🍕🍕🍕C\nA🍕🍕🍕C A🍕🍕🍕C", result4);
}

test "Format" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "b+", null);
    defer re.deinit();

    const result1 = try re.allocFormat(allocator, "abbbc", "$0");
    defer allocator.free(result1);
    try expectEqualStrings("bbb", result1);
    const result2 = try re.allocFormat(allocator, "abbbc", "b=$0");
    defer allocator.free(result2);
    try expectEqualStrings("b=bbb", result2);
}

fn allocFormatUnicode(re: *regex.WRegex, allocator: std.mem.Allocator, input: []const u8, fmt: []const u8) ![]const regex.p_wchar {
    const input_utfw = try regex.utf8ToUtfWideLeAlloc(allocator, input);
    defer allocator.free(input_utfw);
    const fmt_utfw = try regex.utf8ToUtfWideLeAlloc(allocator, fmt);
    defer allocator.free(fmt_utfw);
    return try re.allocFormat(allocator, input_utfw, fmt_utfw);
}
test "Format (unicode)" {
    const allocator = std.testing.allocator;
    var re = try regex.WRegex.compile(allocator, "🍕+", null);
    defer re.deinit();

    const result1 = try allocFormatUnicode(&re, allocator, "a🍕🍕🍕c", "$0");
    defer allocator.free(result1);
    try expectEqualStringsUnicode("🍕🍕🍕", result1);
    const result2 = try allocFormatUnicode(&re, allocator, "a🍕🍕🍕c", "🍕=$0");
    defer allocator.free(result2);
    try expectEqualStringsUnicode("🍕=🍕🍕🍕", result2);
}

test "Captures" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "b", null);
    defer re.deinit();

    {
        const result = try re.capturesAlloc(allocator, "abbbc", true);
        defer result.deinit();

        const captures = result.captures;

        try std.testing.expectEqual(3, captures.len);

        for (captures, 1..) |capture, i| {
            try std.testing.expectEqual(1, capture.groups.len);
            const first = capture.groups[0];
            try expectEqualStrings("b", first.slice);
            try std.testing.expectEqual(i, first.index);
        }
    }

    {
        const result = try re.capturesAlloc(allocator, "abbbc", false);
        defer result.deinit();

        const captures = result.captures;

        try std.testing.expectEqual(1, captures.len);

        for (captures, 1..) |capture, i| {
            try std.testing.expectEqual(1, capture.groups.len);
            const first = capture.groups[0];
            try expectEqualStrings("b", first.slice);
            try std.testing.expectEqual(i, first.index);
        }
    }
}

test "Captures (unicode)" {
    const allocator = std.testing.allocator;
    var re = try regex.WRegex.compile(allocator, "🍕", null);
    defer re.deinit();

    {
        const input = try regex.utf8ToUtfWideLeAlloc(allocator, "a🍕🍕🍕c");
        defer allocator.free(input);

        const result = try re.capturesAlloc(allocator, input, true);
        defer result.deinit();

        const captures = result.captures;

        try std.testing.expectEqual(3, captures.len);

        for (captures, 1..) |capture, i| {
            try std.testing.expectEqual(1, capture.groups.len);
            const first = capture.groups[0];
            try expectEqualStringsUnicode("🍕", first.slice);
            try std.testing.expectEqual(i, first.index);
        }
    }

    {
        const input = try regex.utf8ToUtfWideLeAlloc(allocator, "a🍕🍕🍕c");
        defer allocator.free(input);

        const result = try re.capturesAlloc(allocator, input, false);
        defer result.deinit();

        const captures = result.captures;

        try std.testing.expectEqual(1, captures.len);

        for (captures, 1..) |capture, i| {
            try std.testing.expectEqual(1, capture.groups.len);
            const first = capture.groups[0];
            try expectEqualStringsUnicode("🍕", first.slice);
            try std.testing.expectEqual(i, first.index);
        }
    }
}

test "Strict Search" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "^a(b+)c$", null);
    defer re.deinit();

    if (try re.search("abbbc")) |m| {
        defer m.deinit();
        try expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try expectEqualStrings("bbb", m.groups[1].slice);
        try std.testing.expectEqual(1, m.groups[1].index);
    } else return error.Fail;

    if (try re.search("   abbbc")) |m| {
        defer m.deinit();
        try expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(3, m.groups[0].index);
        try expectEqualStrings("bbb", m.groups[1].slice);
        try std.testing.expectEqual(4, m.groups[1].index);
    }
}

test "Strict Search (unicode)" {
    const allocator = std.testing.allocator;
    var re = try regex.WRegex.compile(allocator, "^a(🍕+)c$", null);
    defer re.deinit();

    const input = try regex.utf8ToUtfWideLeAlloc(allocator, "a🍕🍕🍕c");
    defer allocator.free(input);
    if (try re.search(input)) |m| {
        defer m.deinit();
        try expectEqualStringsUnicode("a🍕🍕🍕c", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try expectEqualStringsUnicode("🍕🍕🍕", m.groups[1].slice);
        try std.testing.expectEqual(1, m.groups[1].index);
    } else return error.Fail;

    const input2 = try regex.utf8ToUtfWideLeAlloc(allocator, "   a🍕🍕🍕c");
    defer allocator.free(input2);
    if (try re.search(input2)) |m| {
        defer m.deinit();
        try expectEqualStringsUnicode("a🍕🍕🍕c", m.groups[0].slice);
        try std.testing.expectEqual(3, m.groups[0].index);
        try expectEqualStringsUnicode("🍕🍕🍕", m.groups[1].slice);
        try std.testing.expectEqual(4, m.groups[1].index);
    }
}

test "Semver 2.0.0" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", null);
    defer re.deinit();

    var valid_iter = std.mem.splitSequence(u8,
        \\0.0.4
        \\1.2.3
        \\1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay
        \\0.0.4
        \\1.2.3
        \\10.20.30
        \\1.1.2-prerelease+meta
        \\1.1.2+meta
        \\1.1.2+meta-valid
        \\1.0.0-alpha
        \\1.0.0-beta
        \\1.0.0-alpha.beta
        \\1.0.0-alpha.beta.1
        \\1.0.0-alpha.1
        \\1.0.0-alpha0.valid
        \\1.0.0-alpha.0valid
        \\1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay
        \\1.0.0-rc.1+build.1
        \\2.0.0-rc.1+build.123
        \\1.2.3-beta
        \\10.2.3-DEV-SNAPSHOT
        \\1.2.3-SNAPSHOT-123
        \\1.0.0
        \\2.0.0
        \\1.1.7
        \\2.0.0+build.1848
        \\2.0.1-alpha.1227
        \\1.0.0-alpha+beta
        \\1.2.3----RC-SNAPSHOT.12.9.1--.12+788
        \\1.2.3----R-S.12.9.1--.12+meta
        \\1.2.3----RC-SNAPSHOT.12.9.1--.12
        \\1.0.0+0.build.1-rc.10000aaa-kk-0.1
        \\99999999999999999999999.999999999999999999.99999999999999999
        \\1.0.0-0A.is.legal
    , "\n");

    var invalid_iter = std.mem.splitSequence(u8,
        \\1
        \\1.2
        \\1.2.3-0123
        \\1.2.3-0123.0123
        \\1.1.2+.123
        \\+invalid
        \\-invalid
        \\-invalid+invalid
        \\-invalid.01
        \\alpha
        \\alpha.beta
        \\alpha.beta.1
        \\alpha.1
        \\alpha+beta
        \\alpha_beta
        \\alpha.
        \\alpha..
        \\beta
        \\1.0.0-alpha_beta
        \\-alpha.
        \\1.0.0-alpha..
        \\1.0.0-alpha..1
        \\1.0.0-alpha...1
        \\1.0.0-alpha....1
        \\1.0.0-alpha.....1
        \\1.0.0-alpha......1
        \\1.0.0-alpha.......1
        \\01.1.1
        \\1.01.1
        \\1.1.01
        \\1.2
        \\1.2.3.DEV
        \\1.2-SNAPSHOT
        \\1.2.31.2.3----RC-SNAPSHOT.12.09.1--..12+788
        \\1.2-RC-SNAPSHOT
        \\-1.0.3-gamma+b7718
        \\+justmeta
        \\9.8.7+meta+meta
        \\9.8.7-whatever+meta+meta
        \\99999999999999999999999.999999999999999999.99999999999999999----RC-SNAPSHOT.12.09.1--------------------------------..12
    , "\n");

    while (valid_iter.next()) |line| {
        // Suppose to match
        if (try re.match(line)) |match| {
            defer match.deinit();
            const groups = match.groups;
            try std.testing.expect(groups.len > 0);
        } else return error.Fail;
    }

    while (invalid_iter.next()) |line| {
        // Not suppose to match
        if (try re.match(line)) |m| {
            m.deinit();
            return error.Fail;
        }
    }
}
