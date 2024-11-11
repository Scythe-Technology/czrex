# czrex
Simple zig wrapper for the C++ regex library

## Example
- Regex
  ```zig
  const std = @import("std");
  const regex = @import("czrex");

  pub fn main() !void {
      const allocator = std.heap.page_allocator;

      var re = try regex.Regex.compile(allocator, "a(b+)", null);
      defer re.deinit();

      if (try re.match("abbbb")) |match| {
          defer match.deinit();
          const groups = match.groups;
          std.debug.print("'{s}' at index: {}\n", .{ groups[0].slice, groups[0].index });
          std.debug.print("'{s}' at index: {}\n", .{ groups[1].slice, groups[1].index });
      }
  }
  ```
- Wide Regex (Unicode)
  ```zig
  const std = @import("std");
  const regex = @import("czrex");

  pub fn main() !void {
      const allocator = std.heap.page_allocator;

      var re = try regex.WRegex.compile(allocator, "a(🍕+)", null);
      defer re.deinit();

      if (try re.match("a🍕🍕🍕🍕")) |match| {
          defer match.deinit();
          const groups = match.groups;
          std.debug.print("'{s}' at index: {}\n", .{ groups[0].slice, groups[0].index });
          std.debug.print("'{s}' at index: {}\n", .{ groups[1].slice, groups[1].index });
      }
  }
  ```