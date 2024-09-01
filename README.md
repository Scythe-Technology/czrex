# czrex
Simple zig wrapper for the C++ regex library

## Example
```zig
const std = @import("std");
const regex = @import("czrex");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var re = try regex.Regex.compile(allocator, "a(b+)");
    defer re.deinit();

    if (try re.match("abbbb")) |match| {
        defer match.deinit();
        const groups = match.getGroups();
        std.debug.print("{s}\n", .{groups[0]});
        std.debug.print("{s}\n", .{groups[1]});
    }
}
```