$j(document).ready(function () {
    $j('[data-role="seek-upload-field"]').each(function () {
        var field = $j(this);
        var pending = $j('[data-role="seek-upload-field-pending-files"]', field);
        var addRemoteBtn = $j('[data-role="seek-upload-field-add-remote"]', field);

        // Populate list of existing content blobs from the embedded JSON
        var existing = $j('[data-role="seek-upload-field-existing"]', field);
        if (existing.length) {
            JSON.parse(existing.html()).forEach(function (blob) {
                pending.append(HandlebarsTemplates['upload/existing_file'](blob));
            })
        }

        // Tabs
        var activateTab = function (id) {
            $j('[data-role="seek-upload-field-tab"]', field).closest('li').removeClass('active');
            $j('[data-role="seek-upload-field-tab"][data-tab-target="' + id + '"]', field).closest('li').addClass('active');
            $j('[data-role="seek-upload-field-tab-pane"]', field).removeClass('active');
            $j('[data-role="seek-upload-field-tab-pane"][data-tab-id="' + id + '"]', field).addClass('active');
        };
        $j('[data-role="seek-upload-field-tab"]', field).click(function () {
            activateTab($j(this).data('tabTarget'));
        });
        // Activate Remote URL tab if URL pre-filled
        if ($j('[data-role="seek-url-checker"] input', field).val()) {
            activateTab('remote-url');
        } else {
            activateTab('local-file');
        }

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
            var urlInput = $j('[data-role="seek-url-checker"] input', field);
            var filenameInput = $j('[data-role="seek-upload-field-filename"]', field);
            var makeLocalCopyCheckbox = $j('[data-role="seek-upload-field-make-copy"]', field)[0];

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
                $j('[data-role="seek-url-checker-result"]', field).html('');
                urlInput.val('');
                filenameInput.val('');
                $j('[data-role="seek-url-checker-msg-success"]', field).hide();
                $j('[data-role="seek-url-checker-msg-too-big"]', field).hide();
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
    $j('[data-role="seek-url-checker"]').each(function () {
        var checker = $j(this);
        var field = checker.parents('[data-role="seek-upload-field"]');
        var input = $j('input', checker);
        var btn = $j('a.btn', checker);
        var url = checker.data('path');
        var result = field.find('[data-role="seek-url-checker-result"]');
        var copyDialog = $j('[data-role="seek-url-checker-msg-success"]', field);
        var tooBig = $j('[data-role="seek-url-checker-msg-too-big"]', field);

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
                lastTestedUrl = input.val();
            }).fail(function (jqXHR) {
                checker.data('urlValid', false);
                result.html(jqXHR.responseText);
            }).always(function () {
                result.spinner('remove');
            });
        };

        var debounceTimeout;
        var lastTestedUrl = null;

        btn.on('click', function () {
            submitUrl();
            return false;
        });

        input.on('change', function () {
            if (debounceTimeout) {
                clearTimeout(debounceTimeout)
            }
            debounceTimeout = setTimeout(function() {
                if (lastTestedUrl !== input.val()) { // Prevent double query, 1 from keypress and 1 from text box losing focus.
                    submitUrl();
                }
            }, 100);
            return true;
        });

        input.on('keypress',function () {
            if (debounceTimeout) {
                clearTimeout(debounceTimeout)
            }
            debounceTimeout = setTimeout(function() {
                submitUrl();
            }, 700);
        });
    });
});
