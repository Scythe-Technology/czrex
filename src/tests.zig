const std = @import("std");
const regex = @import("regex");

// TODO: More testing?

test "Fail" {
    try std.testing.expectError(error.Fail, regex.Regex.compile(std.testing.allocator, "**", null));
}

test "Match" {
    var re = try regex.Regex.compile(std.testing.allocator, "a(b+)c", null);
    defer re.deinit();

    if (try re.match("abbbc")) |m| {
        defer m.deinit();
        try std.testing.expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try std.testing.expectEqualStrings("bbb", m.groups[1].slice);
        try std.testing.expectEqual(1, m.groups[1].index);
    } else return error.Fail;

    if (try re.match("   abbbc")) |m| {
        m.deinit();
        return error.Fail;
    }
}

test "Workaround Match" {
    var re = try regex.Regex.compile(std.testing.allocator, "\\s*(a(b+)c)\\s*", null);
    defer re.deinit();

    if (try re.match("abbbc")) |m| {
        defer m.deinit();
        try std.testing.expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try std.testing.expectEqualStrings("abbbc", m.groups[1].slice);
        try std.testing.expectEqual(0, m.groups[1].index);
        try std.testing.expectEqualStrings("bbb", m.groups[2].slice);
        try std.testing.expectEqual(1, m.groups[2].index);
    } else return error.Fail;

    if (try re.match("   abbbc")) |m| {
        defer m.deinit();
        try std.testing.expectEqualStrings("   abbbc", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try std.testing.expectEqualStrings("abbbc", m.groups[1].slice);
        try std.testing.expectEqual(3, m.groups[1].index);
        try std.testing.expectEqualStrings("bbb", m.groups[2].slice);
        try std.testing.expectEqual(4, m.groups[2].index);
    } else return error.Fail;
}

test "Search" {
    var re = try regex.Regex.compile(std.testing.allocator, "a(b+)c", null);
    defer re.deinit();

    if (try re.search("abbbc")) |m| {
        defer m.deinit();
        try std.testing.expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try std.testing.expectEqualStrings("bbb", m.groups[1].slice);
        try std.testing.expectEqual(1, m.groups[1].index);
    } else return error.Fail;

    if (try re.search("   abbbc")) |m| {
        defer m.deinit();
        try std.testing.expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(3, m.groups[0].index);
        try std.testing.expectEqualStrings("bbb", m.groups[1].slice);
        try std.testing.expectEqual(4, m.groups[1].index);
    }
}

test "Replace" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "b+", null);
    defer re.deinit();

    const result1 = try re.allocReplace(allocator, "abbbc", "$0");
    defer allocator.free(result1);
    try std.testing.expectEqualStrings("abbbc", result1);
    const result2 = try re.allocReplace(allocator, "abbbc", "c");
    defer allocator.free(result2);
    try std.testing.expectEqualStrings("acc", result2);
    const result3 = try re.allocReplace(allocator, "adddc", "c");
    defer allocator.free(result3);
    try std.testing.expectEqualStrings("adddc", result3);
    const result4 = try re.allocReplace(allocator, "abbbc abbbc", "c");
    defer allocator.free(result4);
    try std.testing.expectEqualStrings("acc abbbc", result4);
}

test "ReplaceAll" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "b+", null);
    defer re.deinit();

    const result1 = try re.allocReplaceAll(allocator, "abbbc", "$0");
    defer allocator.free(result1);
    try std.testing.expectEqualStrings("abbbc", result1);
    const result2 = try re.allocReplaceAll(allocator, "abbbc", "c");
    defer allocator.free(result2);
    try std.testing.expectEqualStrings("acc", result2);
    const result3 = try re.allocReplaceAll(allocator, "adddc", "c");
    defer allocator.free(result3);
    try std.testing.expectEqualStrings("adddc", result3);
    const result4 = try re.allocReplaceAll(allocator, "abbbc abbbc", "c");
    defer allocator.free(result4);
    try std.testing.expectEqualStrings("acc acc", result4);
}

test "ReplaceAll CaseInsensitive" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "^(a)(b+)(c)$", regex.FLAG_IGNORECASE);
    defer re.deinit();

    const result1 = try re.allocReplaceAll(allocator, "ABBBC", "$0");
    defer allocator.free(result1);
    try std.testing.expectEqualStrings("ABBBC", result1);
    const result2 = try re.allocReplaceAll(allocator, "ABBBC", "$1c$3");
    defer allocator.free(result2);
    try std.testing.expectEqualStrings("AcC", result2);
    const result3 = try re.allocReplaceAll(allocator, "ADDDC", "$1c$3");
    defer allocator.free(result3);
    try std.testing.expectEqualStrings("ADDDC", result3);
    {
        const result4 = try re.allocReplaceAll(allocator, "ABBBC ABBBC", "$1c$3");
        defer allocator.free(result4);
        try std.testing.expectEqualStrings("ABBBC ABBBC", result4);
        const result5 = try re.allocReplaceAll(allocator, "ABBBC\nABBBC", "$1c$3");
        defer allocator.free(result5);
        try std.testing.expectEqualStrings("ABBBC\nABBBC", result5);
    }
}

test "ReplaceAll CaseInsensitive Multiline" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "^(a)(b+)(c)$", regex.FLAG_IGNORECASE | regex.FLAG_MULTILINE);
    defer re.deinit();

    const result1 = try re.allocReplaceAll(allocator, "ABBBC\nABBBC", "$0");
    defer allocator.free(result1);
    try std.testing.expectEqualStrings("ABBBC\nABBBC", result1);
    const result2 = try re.allocReplaceAll(allocator, "ABBBC\nABBBC", "$1c$3");
    defer allocator.free(result2);
    try std.testing.expectEqualStrings("AcC\nAcC", result2);
    const result3 = try re.allocReplaceAll(allocator, "ADDDC\nADDDC", "$1c$3");
    defer allocator.free(result3);
    try std.testing.expectEqualStrings("ADDDC\nADDDC", result3);
    const result4 = try re.allocReplaceAll(allocator, "ABBBC ABBBC\nABBBC ABBBC", "$1c$3");
    defer allocator.free(result4);
    try std.testing.expectEqualStrings("ABBBC ABBBC\nABBBC ABBBC", result4);
}

test "Format" {
    const allocator = std.testing.allocator;
    var re = try regex.Regex.compile(allocator, "b+", null);
    defer re.deinit();

    const result1 = try re.allocFormat(allocator, "abbbc", "$0");
    defer allocator.free(result1);
    try std.testing.expectEqualStrings("bbb", result1);
    const result2 = try re.allocFormat(allocator, "abbbc", "b=$0");
    defer allocator.free(result2);
    try std.testing.expectEqualStrings("b=bbb", result2);
}

test "Strict Search" {
    var re = try regex.Regex.compile(std.testing.allocator, "^a(b+)c$", null);
    defer re.deinit();

    if (try re.search("abbbc")) |m| {
        defer m.deinit();
        try std.testing.expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(0, m.groups[0].index);
        try std.testing.expectEqualStrings("bbb", m.groups[1].slice);
        try std.testing.expectEqual(1, m.groups[1].index);
    } else return error.Fail;

    if (try re.search("   abbbc")) |m| {
        defer m.deinit();
        try std.testing.expectEqualStrings("abbbc", m.groups[0].slice);
        try std.testing.expectEqual(3, m.groups[0].index);
        try std.testing.expectEqualStrings("bbb", m.groups[1].slice);
        try std.testing.expectEqual(4, m.groups[1].index);
    }
}

test "Semver 2.0.0" {
    var re = try regex.Regex.compile(std.testing.allocator, "^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", null);
    defer re.deinit();

    var valid_iter = std.mem.split(u8,
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

    var invalid_iter = std.mem.split(u8,
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
