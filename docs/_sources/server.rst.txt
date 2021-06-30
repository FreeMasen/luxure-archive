===============
Server
===============

.. lua:autoclass:: Opts

.. lua:autoclass:: Server


Registering Handlers
====================

The ``Server`` table also provides a method for registering a handler for each of the HTTP
methods. The name for each of these methods is formatted into lower snake case and they all take
the path as the first argument and a function as the second argument and all return the server instance.
The function argument will take 2 arguments, the Request first and the Response second.
For example registering a ``GET`` and ``POST`` request handler for the `/` path you would use the following method calls.

.. code-block:: lua

  server:get('/', function(req, res)
    res:send('')
  end)
  :post('/', function(req, res)
    res:send('')
  end)

The following methods are available.


- ``acl``
- ``bind``
- ``checkout``
- ``connect``
- ``copy``
- ``delete``
- ``get``
- ``head``
- ``link``
- ``lock``
- ``m_search``
- ``merge``
- ``mkactivity``
- ``mkcalendar``
- ``mkcol``
- ``move``
- ``notify``
- ``options``
- ``patch``
- ``post``
- ``propfind``
- ``proppatch``
- ``purge``
- ``put``
- ``rebind``
- ``report``
- ``search``
- ``subscribe``
- ``trace``
- ``unbind``
- ``unlink``
- ``unlock``
- ``unsubscribe``
