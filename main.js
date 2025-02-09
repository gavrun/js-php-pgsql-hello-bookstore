var lib = {
    /**flag
     */
    requestIsRunning: false,
    /**contents of sql panel
     */
    sql: '',

    /**separator for contents
     */
    separator: '<hr>',

    /**server action
     * @param action - name of server action
     * @param params - parameters object
     * @param callback - function(data)
     * @return promise
     */
    server: (action, params, callback) => {
        if (!lib.requestIsRunning) {
            lib.requestIsRunning = true;
            $('#loader').show();
            let actionPane = $('#action');
            return actionPane.promise().then(
                () => $.ajax({
                    method: 'post',
                    url: 'server.php?action=' + action,
                    data: params,
                    success: res => {
                        if (res.sql.length) {
                            let sqlText = res.sql.map(
                                s => {
                                    return s.trimLeft().replace(/\n/g, '<br/>').replace(/\t/g, '&nbsp;&nbsp;&nbsp;').replace(/\s/g, ' ');
                                }
                            ).reverse().join(lib.separator);
                            $('<div/>', { class: 'alert alert-info' }).html(sqlText).appendTo(actionPane);
                        }
                        if (res.notice) {
                            $('<p/>', { class: 'alert alert-warning' }).html(res.notice).appendTo(actionPane);
                        }
                        res.info.forEach(
                            info => {
                                $('<p/>', { class: 'alert alert-success' }).html(info).appendTo(actionPane);
                            }
                        );
                        lib.requestIsRunning = false;
                        if (res.err === null) {
                            if (callback !== undefined) {
                                callback(res.data);
                            }
                        }
                        else {
                            $('<p/>', { class: 'alert alert-danger' }).html(res.err.message.replace(/\n\s*\^/, '').replace(/\n/g, '<br/>')).appendTo(actionPane);
                        }
                    },
                    error: e => {
                        lib.requestIsRunning = false;
                        alert('Unexpected server error');
                        console.error(e);
                    },
                    complete: () => {
                        $('#loader').fadeOut('slow');
                        $(actionPane).children().last().css('margin-bottom', '25px');
                        actionPane.slideDown('slow');
                    }
                })
            );
        }
    },

    //display app page
    displayPage: page => {
        lib.clearPanes();
        $.ajax('pages/' + page + '.html')
            .then(
                html => {
                    $('#page').hide().html(html).fadeIn().removeClass().addClass(page);
                },
                () => { $('#page').html('Page "' + page + '" not found'); }
            )
            ;
    },

    //turn form into ajax
    ajaxForm: (selector, callback, extraPars = []) => {
        $(document).off('submit', selector);
        $(document).on(
            'submit',
            selector,
            function (e) {
                e.preventDefault();
                let form = this;
                lib.clearPanes();
                lib.server(
                    $(form).attr('action'),
                    $(form).serialize(),
                    callback === undefined
                        ? () => { console.info('ajax form ok'); }
                        : callback
                );
            }
        );
    },

    //display alert
    alert: (message, style = 'info') => {
        $('<div/>', { class: 'alert alert-' + style + ' fade' }).html(message).appendTo('#alert').addClass('in').delay(2000).slideUp('slow', function () { $(this).remove(); });
    },

    //append contents to pane
    addContents: (oldContents, newContents) => {
        return oldContents + (oldContents && newContents ? lib.separator : '') + newContents;
    },

    //clear contents of sql, success, error, notice panels
    clearPanes: () => {
        $('#action').fadeOut('slow', () => { $('#action').empty(); });
    }
};