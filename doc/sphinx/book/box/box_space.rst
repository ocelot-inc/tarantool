.. include:: ../../directives.rst
.. highlight:: lua

-------------------------------------------------------------------------------
                             Package `box.space`
-------------------------------------------------------------------------------

.. module:: box.space

The ``box.space`` package has the data-manipulation functions ``select``,
``insert``, ``replace``, ``update``, ``delete``, ``get``, ``put``. It also has
members, such as id, and whether or not a space is enabled. Package source code
is available in file
`src/box/lua/box.lua <https://github.com/tarantool/tarantool/blob/master/src/box/lua/box.lua>`_.

A list of all ``box.space`` functions follows, then comes a list of all
``box.space`` members.

.. function:: box.space.space-name:create_index(index-name [, {options} ])

    Create an index. It is **mandatory** to create an index for a tuple set
    before trying to insert tuples into it, or select tuples from it. The
    first created index, which will be used as the primary-key index, must be
    **unique**.

    :param string index-name: name of index, which should not be a number and
                              should not contain special characters;
    :param table options:

    :return: index object
    :rtype:  userdata

    .. container:: table

        **Options for box.space...create_index**

        +---------------+--------------------+-----------------------------+---------------------+
        | Name          | Effect             | Type                        | Default             |
        +===============+====================+=============================+=====================+
        | type          | type of index      | string                      | 'TREE'              |
        |               |                    | ('HASH',     'TREE',        |                     |
        |               |                    | 'BITSET',   'RTREE')        |                     |
        |               |                    |                             |                     |
        |               |                    |                             |                     |
        |               |                    |                             |                     |
        +---------------+--------------------+-----------------------------+---------------------+
        | id            | unique identifier  | number                      | last index's id, +1 |
        +---------------+--------------------+-----------------------------+---------------------+
        | unique        | index is unique    | boolean                     | true                |
        +---------------+--------------------+-----------------------------+---------------------+
        | if_not_exists | no error if        | boolean                     | false               |
        |               | duplicate name     |                             |                     |
        +---------------+--------------------+-----------------------------+---------------------+
        | parts         | field-numbers  +   | ``{field_no, 'NUM'|'STR'}`` | ``{1, 'NUM'}``      |
        |               | types              |                             |                     |
        +---------------+--------------------+-----------------------------+---------------------+

    Possible errors: too many parts. A type options other than TREE, or a
    unique option other than unique, or a parts option with more than one
    field component, is only applicable for the memtx storage engine.

    .. code-block:: lua

        tarantool> s = box.space.space55
        ---
        ...
        tarantool> s:create_index('primary', {unique = true, parts = {1, 'NUM', 2, 'STR'}})
        ---
        ...

.. function:: box.space.space-name:insert{field-value [, field-value ...]}

    Insert a tuple into a space.

    :param userdata      space-name:
    :param lua-value field-value(s): fields of the new tuple.
    :return: the inserted tuple
    :rtype:  tuple

    :except: If a tuple with the same unique-key value already exists,
             returns ``ER_TUPLE_FOUND``.

    .. code-block:: lua

        box.space.tester:insert{5000,'tuple number five thousand'}

.. function:: box.space.space-name:select{field-value [, field-value ...]}

    Search for a tuple or a set of tuples in the given space.

    :param userdata      space-name:
    :param lua-value field-value(s): values to be matched against the index
                                     key, which may be multi-part.

    :return: the tuples whose primary-key fields are equal to the passed
             field-values. If the number of passed field-values is less
             than the number of fields in the primary key, then only the
             passed field-values are compared, so ``select{1,2}`` will match
             a tuple whose primary key is ``{1,2,3}``.
    :rtype:  tuple

    :except: No such space; wrong type.

    Complexity Factors: Index size, Index type.

    .. code-block:: lua

        tarantool> s = box.schema.space.create('tmp', {temporary=true})
        ---
        ...
        tarantool> s:create_index('primary',{parts = {1,'NUM', 2, 'STR'}})
        ---
        ...
        tarantool> s:insert{1,'A'}
        ---
        - [1, 'A']
        ...
        tarantool> s:insert{1,'B'}
        ---
        - [1, 'B']
        ...
        tarantool> s:insert{1,'C'}
        ---
        - [1, 'C']
        ...
        tarantool> s:insert{2,'D'}
        ---
        - [2, 'D']
        ...
        tarantool> -- must equal both primary-key fields
        tarantool> s:select{1,'B'}
        ---
        - - [1, 'B']
        ...
        tarantool> -- must equal only one primary-key field
        tarantool> s:select{1}
        ---
        - - [1, 'A']
          - [1, 'B']
          - [1, 'C']
        ...
        tarantool> -- must equal 0 fields, so returns all tuples
        tarantool> s:select{}
        ---
        - - [1, 'A']
          - [1, 'B']
          - [1, 'C']
          - [2, 'D']
        ...

    For examples of complex ``select``s, where one can specify which index to
    search and what condition to use (for example "greater than" instead of
    "equal to") and how many tuples to return, see the later section
    ``box.space.space-name[.index.index-name]:select``.

.. function:: box.space.space-name:get{field-value [, field-value ...]}

    Search for a tuple in the given space.

    :param userdata      space-name:
    :param lua-value field-value(s): values to be matched against the index
                                     key, which may be multi-part.
    :return: the selected tuple.
    :rtype:  tuple

    :except: If space-name does not exist.

    Complexity Factors: Index size, Index type,
    Number of indexes accessed, WAL settings.

    .. code-block:: lua

        tarantool> box.space.tester:get{1}

.. function:: box.space.space-name:drop()

    Drop a space.

    :return: nil
    :except: If space-name does not exist.

    Complexity Factors: Index size, Index type,
    Number of indexes accessed, WAL settings.

    .. code-block:: lua

        tarantool> box.space.space_that_does_not_exist:drop()

.. function:: box.space.space-name:rename(space-name)

    Rename a space.

    :param string space-name: new name for space.

    :return: nil
    :except: If space-name does not exist.

    .. code-block:: lua

        tarantool> box.space.space55:rename('space56')
        ---
        ...
        tarantool> box.space.space56:rename('space55')
        ---
        ...

.. function:: box.space.space-name:replace{field-value [, field-value ...]}
              box.space.space-name:put{field-value [, field-value ...]}

    Insert a tuple into a space. If a tuple with the same primary key already
    exists, ``box.space...:replace()`` replaces the existing tuple with a new
    one. The syntax variants ``box.space...:replace()`` and
    ``box.space...:put()`` have the same effect; the latter is sometimes used
    to show that the effect is the converse of ``box.space...:get()``.

    :param userdata      space-name:
    :param lua-value field-value(s): fields of the new tuple.

    :return: the inserted tuple.
    :rtype:  tuple

    :except: If a different tuple with the same unique-key
             value already exists, returns ``ER_TUPLE_FOUND``.
             (This would only happen if there was a secondary
             index. By default secondary indexes are unique.)

    Complexity Factors: Index size, Index type,
    Number of indexes accessed, WAL settings.

    .. code-block:: lua

        tarantool> box.space.tester:replace{5000, 'New value'}

.. function:: box.space.space-name:update(key, {{operator, field_no, value}, ...})

    Update a tuple.

    The ``update`` function supports operations on fields — assignment,
    arithmetic (if the field is unsigned numeric), cutting and pasting
    fragments of a field, deleting or inserting a field. Multiple
    operations can be combined in a single update request, and in this
    case they are performed atomically and sequentially. Each operation
    requires specification of a field number. When multiple operations
    are present, the field number for each operation is assumed to be
    relative to the most recent state of the tuple, that is, as if all
    previous operations in a multi-operation update have already been
    applied. In other words, it is always safe to merge multiple update
    invocations into a single invocation, with no change in semantics.

    :param userdata space-name:
    :param lua-value key: primary-key field values, must be passed as a Lua
                          table if key is multi-part
    :param table {operator, field_no, value}: a group of arguments for each
            operation, indicating what the operation is, what field the
            operation will apply to, and what value will be applied. For
            some operations the field number can be -1, meaning the last
            field in the tuple. Possible operators are: “+” for addition,
            “-” for subtraction, “&” for bitwise AND, “|” for bitwise OR,
            “^” for bitwise exclusive OR (XOR), “:” for string splice, “!”
            for insert, “#” for delete. Thus in the instruction
            ``s:update(44, {{'+',1,55},{'=',3,'x'}})`` the primary-key
            value is 44, the operators are '+' and '=' meaning "add a value
            to a field and then assign a value to a field", the first
            affected field is field 1 and the value which will be added to
            it is 55, the second affected field is field 3 and the value
            which will be assigned to it is 'x'.

    :return: the updated tuple.
    :rtype:  tuple

    :except: it is illegal to modify a primary-key field.

    Complexity Factors: Index size, Index type, number of indexes accessed, WAL
    settings.

    .. code-block:: lua

        -- Assume that the initial state of the database is ...
        --   tester has one tuple set and one primary key whose type is 'NUM'.
        --   There is one tuple, with field[1] = 999 and field[2] = 'A'.

        -- In the following update ...
        --   The first argument is tester, that is, the affected space is tester
        --   The second argument is 999, that is, the affected tuple is identified by
        --     primary key value = 999
        --   The third argument is '=', that is, there is one operation, assignment
        --     to a field
        --   The fourth argument is 2, that is, the affected field is field[2]
        --   The fifth argument is 'B', that is, field[2] contents change to 'B'
        --   Therefore, after the following update, field[1] = 999 and field[2] = 'B'.
        box.space.tester:update(999, {{'=', 2, 'B'}})

        -- In the following update, the arguments are the same, except that ...
        --   the key is passed as a Lua table (inside braces). This is unnecessary
        --   when the primary key has only one field, but would be necessary if the
        --   primary key had more than one field.
        --   Therefore, after the following update, field[1] = 999 and field[2] = 'B'
        --     (no change).
        box.space.tester:update({999}, {{'=', 2, 'B'}})

        -- In the following update, the arguments are the same, except that ...
        --    The fourth argument is 3, that is, the affected field is field[3].
        --    It is okay that, until now, field[3] has not existed. It gets added.
        --    Therefore, after the following update, field[1] = 999, field[2] = 'B',
        --      field[3] = 1.
        box.space.tester:update({999}, {{'=', 3, 1}})

        -- In the following update, the arguments are the same, except that ...
        --    The third argument is '+', that is, the operation is addition rather
        --      than assignment.
        --    Since field[3] previously contained 1, this means we're adding 1 to 1.
        --    Therefore, after the following update, field[1] = 999, field[2] = 'B',
        --      field[3] = 2.
        box.space.tester:update({999}, {{'+', 3, 1}})

        -- In the following update ...
        --    The idea is to modify two fields at once.
        --    The formats are '|' and '=', that is, there are two operations, OR and
        --      assignment.
        --    The fourth and fifth arguments mean that field[3] gets ORed with 1.
        --    The seventh and eighth arguments mean that field[2] gets assigned 'C'.
        --    Therefore, after the following update, field[1] = 999, field[2] = 'C',
        --      field[3] = 3.
        box.space.tester:update({999}, {{'|', 3, 1}, {'=', 2, 'C'}})

        -- In the following update ...
        --    The idea is to delete field[2], then subtract 3 from field[3], but ...
        --    after the delete, there is a renumbering -- so field[3] becomes field[2]
        --    before we subtract 3 from it, and that's why the seventh argument is 2 not 3.
        --    Therefore, after the following update, field[1] = 999, field[2] = 0.
        box.space.tester:update({999}, {{'-- ', 2, 1}, {'-', 2, 3}})

        -- In the following update ...
        --    We're making a long string so that splice will work in the next example.
        --    Therefore, after the following update, field[1] = 999, field[2] = 'XYZ'.
        box.space.tester:update({999}, {{'=', 2, 'XYZ'}})

        -- In the following update ...
        --    The third argument is ':', that is, this is the example of splice.
        --    The fourth argument is 2 because the change will occur in field[2].
        --    The fifth argument is 2 because deletion will begin with the second byte.
        --    The sixth argument is 1 because the number of bytes to delete is 1.
        --    The seventh argument is '!!' because '!!' is to be added at this position.
        --    Therefore, after the following update, field[1] = 999, field[2] = 'X!!Z'.
        box.space.tester:update({999}, {{':', 2, 2, 1, '!!'}})

.. function:: box.space.space-name:delete{field-value [, field-value ...]}

    Delete a tuple identified by a primary key.

    :param userdata space-name:
    :param lua-value field-value(s): values to match against keys
                                     in the primary index.

    :return: the deleted tuple
    :rtype:  tuple

    Complexity Factors: Index size, Index type

    .. code-block:: lua

        tarantool> box.space.tester:delete(0)
        ---
        - [0, 'My first tuple']
        ...
        tarantool> box.space.tester:delete(0)
        ---
        ...
        tarantool> box.space.tester:delete('a')
        ---
        - error: 'Supplied key type of part 0 does not match index part type:
          expected NUM'
        ...

.. data::     space-name.id

    Ordinal space number. Spaces can be referenced by either name or
    number. Thus, if space 'tester' has id = 800, then
    ``box.space.tester:insert{0}`` and ``box.space[800]:insert{0}``
    are equivalent requests.

    :rtype: number

.. data::     space-name.enabled

    Whether or not this space is enabled.
    The value is false if there is no index.

    :rtype: boolean

.. data::     space-name.field_count

    The required field count for all tuples in this space. The field_count
    can be set initially with
    ``box.schema.space.create... field_count = new-field-count-value ...``.
    The default value is 0, which means there is no required field count.

    :rtype: number

.. data::     space-name.index[]

    A container for all defined indexes. An index is a Lua object of type
    :mod:`box.index` with methods to search tuples and iterate over them in
    predefined order.

    :rtype: table

    .. code-block: lua

        tarantool> box.space.tester.id
        ---
        - 512
        ...
        tarantool> box.space.tester.field_count
        ---
        - 0
        ...
        tarantool> box.space.tester.index.primary.type
        ---
        - TREE
        ...

.. function:: box.space.space-name:len()

    .. NOTE::

        The ``len()`` function is only applicable for the memtx storage engine.

    :return: Number of tuples in the space.

    .. code-block:: lua

        tarantool> box.space.tester:len()
        ---
        - 2
        ...

.. function:: box.space.space-name:truncate()

    Deletes all tuples.

    Complexity Factors: Index size, Index type, Number of tuples accessed.

    :return: nil

    .. code-block:: lua

        tarantool> box.space.tester:truncate()
        ---
        ...
        tarantool> box.space.tester:len()
        ---
        - 0
        ...

.. function:: box.space.space-name:inc{field-value [, field-value ...]}

    Increments a counter in a tuple whose primary key matches the
    ``field-value(s)``. The field following the primary-key fields
    will be the counter. If there is no tuple matching the
    ``field-value(s)``, a new one is inserted with initial counter
    value set to 1.

    :param userdata space-name:
    :param lua-value field-value(s): values which must match the primary key.
    :return: the new counter value
    :rtype:  number

    Complexity Factors: Index size, Index type, WAL settings.

    .. code-block:: lua

        tarantool> s = box.schema.space.create('forty_second_space')
        ---
        ...
        tarantool> s:create_index('primary', {unique = true, parts = {1, 'NUM', 2, 'STR'}})
        ---
        ...
        tarantool> box.space.forty_second_space:inc{1,'a'}
        ---
        - 1
        ...
        tarantool> box.space.forty_second_space:inc{1,'a'}
        ---
        - 2
        ...

.. function:: box.space.space-name:dec{field-value [, field-value ...]}

    Decrements a counter in a tuple whose primary key matches the
    ``field-value(s)``. The field following the primary-key fields
    will be the counter. If there is no tuple matching the
    ``field-value(s)``, a new one is not inserted. If the counter value drops
    to zero, the tuple is deleted.

    :param userdata space-name:
    :param lua-value field-value(s): values which must match the primary key.
    :return: the new counter value
    :rtype:  number

    Complexity Factors: Index size, Index type, WAL settings.

    .. code-block:: lua

        tarantool> s = box.schema.space.create('space19')
        ---
        ...
        tarantool> s:create_index('primary', {unique = true, parts = {1, 'NUM', 2, 'STR'}})
        ---
        ...
        tarantool> box.space.space19:insert{1,'a',1000}
        ---
        - [1, 'a', 1000]
        ...
        tarantool> box.space.space19:dec{1,'a'}
        ---
        - 999
        ...
        tarantool> box.space.space19:dec{1,'a'}
        ---
        - 998
        ...

.. function:: box.space.space-name:auto_increment{field-value [, field-value ...]}

    Insert a new tuple using an auto-increment primary key. The space specified
    by space-name must have a NUM primary key index of type TREE. The
    primary-key field will be incremented before the insert.

    :param userdata space-name:
    :param lua-value field-value(s): values for the tuple's fields,
                                     other than the primary-key field.

    :return: the inserted tuple.
    :rtype:  tuple

    Complexity Factors: Index size, Index type,
    Number of indexes accessed, WAL settings.

    :except: index has wrong type or primary-key indexed field is not a number.

    .. code-block:: lua

        tarantool> box.space.tester:auto_increment{'Fld#1', 'Fld#2'}
        ---
        - [1, 'Fld#1', 'Fld#2']
        ...
        tarantool> box.space.tester:auto_increment{'Fld#3'}
        ---
        - [2, 'Fld#3']
        ...

.. function:: box.space.space-name:pairs()

    A helper function to prepare for iterating over all tuples in a space.

    :return: function which can be used in a for/end loop. Within the loop, a value is returned for each iteration.
    :rtype:  function, tuple

    .. code-block:: lua

        tarantool> s = box.schema.space.create('space33')
        ---
        ...
        tarantool> -- index 'X' has default parts {1,'NUM'}
        tarantool> s:create_index('X', {})
        ---
        ...
        tarantool> s:insert{0,'Hello my '}; s:insert{1,'Lua world'}
        ---
        ...
        tarantool> tmp = ''; for k, v in s:pairs() do tmp = tmp .. v[2] end
        ---
        ...
        tarantool> tmp
        ---
        - Hello my Lua world
        ...

.. data::     _schema

    ``_schema`` is a system tuple set. Its single tuple contains these fields:
    ``'version', major-version-number, minor-version-number``.

    The following function will display all fields in all tuples of ``_schema``.

    .. code-block:: lua

        console = require('console'); console.delimiter('!')
        function example()
            local ta = {}, i, line
            for k, v in box.space._schema:pairs() do
                i = 1
                line = ''
                while i <= #v do line = line .. v[i] .. ' ' i = i + 1 end
                table.insert(ta, line)
            end
            return ta
        end!
        console.delimiter('')!


    Here is what ``example()`` returns in a typical installation:

    .. code-block:: lua

        tarantool> example()
        ---
        - - 'cluster 1ec4e1f8-8f1b-4304-bb22-6c47ce0cf9c6 '
          - 'max_id 520 '
          - 'version 1 6 '
        ...

.. data::     _space

    ``_space`` is a system tuple set. Its tuples contain these fields:
    ``id, uid, space-name, engine, field_count, temporary``.

    The following function will display all simple fields
    in all tuples of ``_space``.

    .. code-block:: lua

        console = require('console'); console.delimiter('!')
        function example()
            local ta = {}, i, line
            for k, v in box.space._space:pairs() do
                i = 1
                line = ''
                while i <= #v do
                    if type(v[i]) ~= 'table' then
                        line = line .. v[i] .. ' '
                    end
                    i = i + 1
                end
                table.insert(ta, line)
            end
            return ta
        end!
        console.delimiter('')!

    Here is what ``example()`` returns in a typical installation:

    .. code-block:: lua

        tarantool> example()
        ---
        - - '272 1 _schema memtx 0  '
          - '280 1 _space memtx 0  '
          - '288 1 _index memtx 0  '
          - '296 1 _func memtx 0  '
          - '304 1 _user memtx 0  '
          - '312 1 _priv memtx 0  '
          - '320 1 _cluster memtx 0  '
          - '512 1 tester memtx 0  '
          - '513 1 origin sophia 0  '
          - '514 1 archive memtx 0  '
        ...

.. data::     _index

    ``_index`` is a system tuple set. Its tuples contain these fields:
    ``space-id index-id index-name index-type index-is-unique
    index-field-count [tuple-field-no, tuple-field-type ...]``.

    The following function will display all fields in all tuples of _index.

    .. code-block:: lua

        console = require('console'); console.delimiter('!')
        function example()
            local ta = {}, i, line
            for k, v in box.space._index:pairs() do
                i = 1
                line = ''
                    while i <= #v do line = line .. v[i] .. ' ' i = i + 1 end
                table.insert(ta, line)
            end
            return ta
        end!
        console.delimiter('')!

    Here is what ``example()`` returns in a typical installation:

    .. code-block:: lua

        tarantool> example()
        ---
        - - '272 0 primary tree 1 1 0 str '
          - '280 0 primary tree 1 1 0 num '
          - '280 1 owner tree 0 1 1 num '
          - '280 2 name tree 1 1 2 str '
          - '288 0 primary tree 1 2 0 num 1 num '
          - '288 2 name tree 1 2 0 num 2 str '
          - '296 0 primary tree 1 1 0 num '
          - '296 1 owner tree 0 1 1 num '
          - '296 2 name tree 1 1 2 str '
          - '304 0 primary tree 1 1 0 num '
          - '304 1 owner tree 0 1 1 num '
          - '304 2 name tree 1 1 2 str '
          - '312 0 primary tree 1 3 1 num 2 str 3 num '
          - '312 1 owner tree 0 1 0 num '
          - '312 2 object tree 0 2 2 str 3 num '
          - '320 0 primary tree 1 1 0 num '
          - '320 1 uuid tree 1 1 1 str '
          - '512 0 primary tree 1 1 0 num '
          - '513 0 first tree 1 1 0 NUM '
          - '514 0 first tree 1 1 0 STR '
        ...

.. data::     _user

    ``_user`` is a new system tuple set for
    support of the `authorization feature`_.

.. data::     _priv

    ``_priv`` is a new system tuple set for
    support of the `authorization feature`_.

.. data::     _cluster

    ``_cluster`` is a new system tuple set
    for support of the `replication feature`_.

.. _authorization feature: http://tarantool.org/doc/user_guide.html#authentication
.. _replication feature: http://tarantool.org/doc/user_guide.html#replication

=================================================
                     Example
=================================================

This function will illustrate how to look at all the spaces, and for each
display: approximately how many tuples it contains, and the first field of
its first tuple. The function uses Tarantool ``box.space`` functions ``len()``
and ``pairs()``. The iteration through the spaces is coded as a scan of the
``_space`` system tuple set, which contains metadata. The third field in
``_space`` contains the space name, so the key instruction
"``space_name = v[3]``" means "``space_name`` = the ``space_name`` field in
the tuple of ``_space`` that we've just fetched with ``pairs()``". The function
returns a table.

.. code-block:: lua

    console = require('console'); console.delimiter('!')
    function example()
        local tuple_count, space_name, line
        local ta = {}
        for k, v in box.space._space:pairs() do
            space_name = v[3]
            if box.space[space_name].index[0] ~= nil then
                tuple_count = box.space[space_name]:len()
            else
                tuple_count = 0
            end
            line = space_name .. ' tuple_count =' .. tuple_count
            if tuple_count > 0 then
                for k1, v1 in box.space[space_name]:pairs() do
                    line = line .. '. first field in first tuple = ' .. v1[1]
                    break
                end
            end
            table.insert(ta, line)
        end
        return ta
    end!
    console.delimiter('')!

... And here is what happens when one invokes the function:

.. code-block:: lua

    tarantool> example()
    ---
    - - _schema tuple_count =3. first field in first tuple = cluster
      - _space tuple_count =15. first field in first tuple = 272
      - _index tuple_count =25. first field in first tuple = 272
      - _func tuple_count =1. first field in first tuple = 1
      - _user tuple_count =4. first field in first tuple = 0
      - _priv tuple_count =6. first field in first tuple = 1
      - _cluster tuple_count =1. first field in first tuple = 1
      - tester tuple_count =2. first field in first tuple = 1
      - origin tuple_count =0
      - archive tuple_count =13. first field in first tuple = test_0@tarantool.org
      - space55 tuple_count =0
      - tmp tuple_count =0
      - forty_second_space tuple_count =1. first field in first tuple = 1
    ...