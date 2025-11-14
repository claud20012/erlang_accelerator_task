Erlang Accelerator Task Queue
=====

The purpose of this application is to demonstrate the tools we commonly use when writing Erlang code.

[http_handler] -> [db]
               -> [scheduler] -> [worker] -> [task] -> [http]
                                                    -> [shell]

Build
-----

    $ rebar3 compile

HTTP API
-----

Get all tasks.

    GET /tasks

Get status of a task.

    GET /tasks/:id

Put a new task to app's queue.
Note: Start with the http type, but feel free to explore other options like shell.

    POST /tasks
    {
        "task": {
            "type": "http",
            "payload": {
                "url": "...",
                "method": "...",
                "body": "...",
                "headers": {}
            },
            "trigger_at": "<DateTime in RFC3339>"
        }
    }

    {
        "task": {
            "id": "...",
            "type": "http",
            "config": {...},
            "trigger_at": "<DateTime in RFC3339>"
            "status": "pending" | "active" | "completed" | "failed"
        }
    }

To delete a task from the queue. If the task is active, completed, or failed, nothing should happen.

    DELETE /tasks/:id

Note: for tests you can use https://webhook.site, or other alternatives

Dependencies
-----

* [cowboy](https://ninenines.eu/docs/en/cowboy/2.14/guide/) - to receive incoming HTTP requests
* [epgsql](https://github.com/epgsql/epgsql) - to work with PostgreSQL
* [hackney](https://hexdocs.pm/hackney/readme.html) - to make HTTP requests
* [poolboy](https://github.com/devinus/poolboy) - to run the worker pool
