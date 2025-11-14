const std = @import("std");

/// Return a new names bag.
///
/// A NamesBag is a bijective mapping S → {0, …, n-1}.
///
/// The NamesBag is a dictionary that assignes indices in increasing
/// order to names (strings). The primary use case is to enumerate a
/// set of names so that they can be identified using integral
/// indices.
///
/// The original name can also be retrieved by passing the index.
pub fn NamesBag(comptime T: type) type {
    const Keys = std.StringHashMapUnmanaged(T);
    const NameList = std.ArrayList([]const u8);
    return struct {
        allocator: std.mem.Allocator,
        names: Keys,
        names_by_index: NameList,

        const Self = @This();

        /// Create a new empty names bag.
        pub fn init(alloc: std.mem.Allocator) Self {
            return .{
                .allocator = alloc,
                .names = .empty,
                .names_by_index = .empty,
            };
        }

        /// Release the names bag.
        pub fn deinit(self: *Self) void {
            self.names.deinit(self.allocator);
            for (self.names_by_index.items) |n| self.allocator.free(n);
            self.names_by_index.deinit(self.allocator);
        }

        /// Return the index of an existing name or null.
        pub fn getOrNull(self: *const Self, name: []const u8) ?T {
            return self.names.get(name);
        }

        /// Return the index of a name.
        ///
        /// If the name is not contained in the bag, it is added
        /// and assigned the next index.
        pub fn getOrPut(self: *Self, name: []const u8) !T {
            var entry = try self.names.getOrPutAdapted(self.allocator, name, std.hash_map.StringContext{});
            if (!entry.found_existing) {
                const new_idx: T = @intCast(self.names_by_index.items.len);
                const new_name = try self.allocator.dupe(u8, name);
                errdefer self.allocator.free(new_name);
                try self.names_by_index.append(self.allocator, new_name);
                entry.key_ptr.* = new_name;
                entry.value_ptr.* = new_idx;
            }
            return entry.value_ptr.*;
        }

        /// Return the name of an (existing) index.
        ///
        /// Returns null of the index is out of bounds.
        pub fn getNameOrNull(self: *const Self, index: T) ?[]const u8 {
            const idx: usize = @intCast(index);
            return if (idx < self.names_by_index.items.len)
                self.names_by_index.items[idx]
            else
                return null;
        }

        /// Return the name of an (existing) index.
        ///
        /// The index must be valid.
        pub fn getName(self: *const Self, index: T) []const u8 {
            return self.names_by_index.items[@intCast(index)];
        }

        /// Returns the number of names in this bag.
        pub fn count(self: *const Self) usize {
            return self.names_by_index.items.len;
        }
    };
}

test "New NamesBag" {
    var names = NamesBag(u32).init(std.testing.allocator);
    defer names.deinit();

    try std.testing.expectEqual(0, names.count());
}

test "NamesBag" {
    var names = NamesBag(u32).init(std.testing.allocator);
    defer names.deinit();

    try std.testing.expectEqual(null, names.getOrNull("foo"));
    try std.testing.expectEqual(null, names.getOrNull("bar"));
    try std.testing.expectEqual(0, names.getOrPut("foo"));
    try std.testing.expectEqual(0, names.getOrNull("foo"));
    try std.testing.expectEqual(0, names.getOrPut("foo"));
    try std.testing.expectEqual(null, names.getOrNull("bar"));
    try std.testing.expectEqual(1, names.count());
    try std.testing.expectEqual(1, names.getOrPut("bar"));
    try std.testing.expectEqual(0, names.getOrPut("foo"));
    try std.testing.expectEqual(1, names.getOrPut("bar"));
    try std.testing.expectEqual(0, names.getOrNull("foo"));
    try std.testing.expectEqual(1, names.getOrNull("bar"));
    try std.testing.expectEqual(2, names.count());
    try std.testing.expectEqualStrings("foo", names.getName(0));
    try std.testing.expectEqualStrings("bar", names.getName(1));
    try std.testing.expectEqual(null, names.getNameOrNull(2));
}
