$j(document).ready(function () {
    $j('[data-seek-upload-field]').each(function () {
        var field = $j(this);
        var pending = $j('[data-seek-upload-field-pending]', field);
        var addRemoteBtn = $j('[data-seek-upload-field-add-remote]', field);

        // Populate list of existing content blobs from the embedded JSON
        var existing = $j('[data-seek-upload-field-existing]', field);
        if (existing.length) {
            JSON.parse(existing.html()).forEach(function (blob) {
                pending.append(HandlebarsTemplates['upload/existing_file'](blob));
            })
        }

        // Tabs
        $j('[data-seek-upload-field-tab]', field).click(function () {
            $j('[data-seek-upload-field-tab]', field).removeClass('active');
            $j('[data-seek-upload-field-tab-pane]', field).removeClass('active');
            $j('[data-seek-upload-field-tab-pane="' + $j(this).data('seekUploadFieldTab') + '"]', field).addClass('active');
            $j(this).addClass('active');
        });

        // Local file
        var addLocalFile = function () {
            var newField = HandlebarsTemplates['upload/file_field']();
            $j(this).parent().append(newField);
            var filename = this.value.split(/\\/)[this.value.split(/\\/).length - 1];
            var listItem = $j(HandlebarsTemplates['upload/local_file']({ text: filename }));
            pending.append(listItem);
            listItem.append($j(this).hide());
        };

        field.on('change', 'input[type=file][data-batch-upload=true]', addLocalFile);

        // Remote file
        var addRemoteFile = function () {
            var urlInput = $j('[data-seek-url-checker] input', field);
            var filenameInput = $j('[data-seek-upload-field-filename]', field);
            var makeLocalCopyCheckbox = $j('[data-seek-upload-field-make-copy]', field)[0];

            var remoteFile = {
                dataURL: urlInput.val(),
                makeALocalCopy: (makeLocalCopyCheckbox && makeLocalCopyCheckbox.checked) ? "1" : "0",
                originalFilename: filenameInput.val()
            };
            remoteFile.text = remoteFile.originalFilename.trim() ? remoteFile.originalFilename : remoteFile.dataURL;

            var parsed = parseUri(remoteFile.dataURL);
            if (!parsed.host || parsed.host === "null") {
                alert("An invalid URL was provided");
            }
            else {
                $j('[data-seek-url-checker-result]', field).html('');
                urlInput.val('');
                filenameInput.val('');
                $j('[data-seek-url-checker-copy-dialog]', field).hide();
                $j('[data-seek-url-checker-too-big]', field).hide();
                pending.append(HandlebarsTemplates['upload/remote_file'](remoteFile));
            }
        };

        addRemoteBtn.click(addRemoteFile);

        // Remove file
        pending.on('click', '.remove-file', function () {
            $j(this).parent('li').remove();
            return false;
        });
    });

    // Code for checking URL and showing preview
    $j('[data-seek-url-checker]').each(function () {
        var checker = $j(this);
        var field = checker.parents('[data-seek-upload-field]');
        var input = $j('input', checker);
        var btn = $j('a.btn', checker);
        var url = checker.data('seekUrlChecker');
        var result = field.find('[data-seek-url-checker-result]');
        var copyDialog = $j('[data-seek-url-checker-copy-dialog]', field);
        var tooBig = $j('[data-seek-url-checker-too-big]', field);

        var submitUrl = function () {
            result.html('').spinner('add');
            copyDialog.hide();
            tooBig.hide();
            $j.ajax({
                url: url,
                method: 'POST',
                data: { data_url: input.val() },
                dataType: 'html'
            }).done(function (data) {
                checker.data('urlValid', true);
                result.html(data);
                var json = $j('script', result);
                if (json.length) {
                    var info = JSON.parse($j('script', result).html());
                    if (info.allow_copy) {
                        copyDialog.show();
                    } else {
                        tooBig.show();
                    }
                }
            }).fail(function (jqXHR) {
                checker.data('urlValid', false);
                result.html(jqXHR.responseText);
            }).always(function () {
                result.spinner('remove');
            });
        };

        btn.on('click', function () {
            submitUrl();
            return false;
        });

        input.on('change', function () {
            setTimeout(function() {
                submitUrl();
            }, 0);
            return true;
        });

        input.on('keypress',function () {
            submitUrl(false);
        });
    });
});
