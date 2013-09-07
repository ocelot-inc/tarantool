-- ----------------------------------------------------------------
-- LIMITS
-- ----------------------------------------------------------------
box.schema.SYSTEM_ID_MIN
box.schema.FIELD_MAX
box.schema.NAME_MAX
box.schema.INDEX_ID
box.schema.SPACE_ID
box.schema.INDEX_MAX
box.schema.SPACE_MAX
box.schema.SYSTEM_ID_MAX
box.schema.SCHEMA_ID
-- ----------------------------------------------------------------
-- CREATE SPACE
-- ----------------------------------------------------------------

s = box.schema.create_space('tweedledum')
-- space already exists
box.schema.create_space('tweedledum')
-- create if not exists
s = box.schema.create_space('tweedledum', { if_not_exists = true })

s:drop()
-- no such space
s:drop()
-- explicit space id
s = box.schema.create_space('tweedledum', { id = 3000 })
s.n
-- duplicate id
box.schema.create_space('tweedledee', { id = 3000 })
-- stupid space id
box.schema.create_space('tweedledee', { id = 'tweedledee' })
s:drop()
-- too long space name
box.schema.create_space(string.rep('tweedledee', 100))
-- space name limit
box.schema.create_space(string.rep('t', box.schema.NAME_MAX)..'_')
s = box.schema.create_space(string.rep('t', box.schema.NAME_MAX - 1)..'_')
s.name
s:drop()
s = box.schema.create_space(string.rep('t', box.schema.NAME_MAX - 2)..'_')
s.name
s:drop()
-- space with no indexes - test update, delete, select, truncate
s = box.schema.create_space('tweedledum')
s:insert(0)
s:select(0)
s:select_range(0, 0, 0)
s:delete(0)
s:update(0, "=p", 0, 0)
s:replace(0)
s.index[0]
s:truncate()
s.enabled
-- enabled/disabled transition
s:create_index('primary', 'hash', { parts = { 0, 'num' } })
s.enabled
-- rename space - same name
s:rename('tweedledum')
s.name
-- rename space - different name
s:rename('tweedledee')
s.name
-- the reference from box.space[] to the space by old name should be gone
box.space['tweedledum']
-- rename space - bad name
s:rename(string.rep('t', box.schema.NAME_MAX * 2))
s.name
-- access to a renamed space
s:insert(0)
s:delete(0)
-- cleanup
s:drop()
-- create a space with reserved id (ok, but warns in the log)
s = box.schema.create_space('test', { id = 256 })
s.n
s:drop()
s = box.schema.create_space('test', { arity = 2 })
s.arity
s:create_index('primary', 'tree', { parts = { 0, 'num' } })
-- arity actually works
s:insert(1)
s:insert(1, 2)
s:insert(1, 2, 3)
s:select(0)
-- increase arity -- error
box.space['_space']:update(s.n, "=p", 1, 3)
s:select(0)
-- decrease arity - error
box.space['_space']:update(s.n, "=p", 1, 1)
-- remove arity - ok
box.space['_space']:update(s.n, "=p", 1, 0)
s:select(0)
-- increase arity - error
box.space['_space']:update(s.n, "=p", 1, 3)
s:truncate()
s:select(0)
-- set arity of an empty space
box.space['_space']:update(s.n, "=p", 1, 3)
s:select(0)
-- arity actually works
s:insert(3, 4)
s:insert(3, 4, 5)
s:insert(3, 4, 5, 6)
s:insert(7, 8, 9)
s:select(0)
s:drop()

-- Test plan
-- --------
-- add space:
-- ---------
-- - arity change - empty, non-empty space
-- - test that during commit phase
--   -> inject error at commit, inject error at rollback
-- - check transition of a space to "disabled" on
-- deletion of primary key
-- wal:
-- - too many spaces
-- - find out why we run short of 32k formats
-- - longevity test for create/drop
--
--
-- add index:
-- ---------
--     - a test case for every constraint in key_def_check
--     - test that during the rebuild there is a duplicate
--     according to the new index
--     - index rebuild -> no field in the index (validate tuple
--     during build)
--     - alter unique -> non unique
--     - alter index type
--     - index access by name
--     - alter add key part
--     - arbitrary index
--     - index count exhaustion
--     - test that during commit phase
--       -> inject error at commit, inject error at rollback
--     - add check that doesn't allow drop of a primary
--       key in presence of other keys, or moves the space
--       to disabled state otherwise.
--
--     - add identical index - verify there is no rebuild
--     - rename index (all non-essential propeties)
--       -> duplicate key
--     - inject fiber sleep during commit, so that some stuff is added
--     (test crap which happens while there is a record to the wal
--     - test ambiguous field type when adding an index (ER_FIELD_TYPE_MISMATCH)
--     - test addition of a new index on data which it can't handle
--
-- space cache
-- -----------
-- - all the various kinds of reference to a dropped space
--   - iterator to index
--   index to space
--   space ot index
--   variable
--   key def
--   all userdata given away to lua - think how
--
--
-- usability
-- ---------
-- - space name in all error messages!
--         error: Duplicate key exists in unique index 1 (ugly)
--
-- triggers
-- --------
-- - test that after disabling triggers we can
-- create an empty snapshot
-- - test for run_triggers
--
-- recovery
-- --------
--  - add primary key in snapshot
--  - add secondary key in snapshot
--  - add primary key in xlog
--  - add secondary key in xlog
--  - the same for an empty space and a space with data
--  - test start from a space entry added in xlog
--  - test start from a space entry dropped in xlog
--  - test enabled/disabled property for these
--  spaces and space from a snapshot
--
--
-- features
--------
-- - ffi function to enable/disable space