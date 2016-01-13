var zenodoExport = {
    creatorList: [],

    setLicenseUrl: function () {
        var element = $j('#license-select option:selected');
        var link = $j('#license-url');

        link.attr('href', element.data('url'));
        link.html(element.data('url'));
    },

    enableSection: function (sectionElement) {
        sectionElement.show().children(":input").prop("disabled", false);
    },

    disableSection: function (sectionElement) {
        sectionElement.hide().children(":input").prop("disabled", true);
    },

    toggleSections: function () {
        var licenseSection = $j('#license-section');
        var dateSection = $j('#embargo-date-section');
        var conditionsSection = $j('#access-conditions-section');

        if (this.value == 'open') {
            zenodoExport.enableSection(licenseSection);
            zenodoExport.disableSection(dateSection);
            zenodoExport.disableSection(conditionsSection);
        } else if (this.value == 'embargoed') {
            zenodoExport.enableSection(licenseSection);
            zenodoExport.enableSection(dateSection);
            zenodoExport.disableSection(conditionsSection);
        } else if (this.value == 'restricted') {
            zenodoExport.disableSection(licenseSection);
            zenodoExport.disableSection(dateSection);
            zenodoExport.enableSection(conditionsSection);
        } else if (this.value == 'closed') {
            zenodoExport.disableSection(licenseSection);
            zenodoExport.disableSection(dateSection);
            zenodoExport.disableSection(conditionsSection);
        }
    },

    renderCreatorList: function () {
        var html = '';

        zenodoExport.creatorList.each(function (c) {
            html += HandlebarsTemplates['zenodo/creator'](c);
        });

        $j('#creators').html(html);
    },

    addCreator: function () {
        var creator = { name: $j('#add-creator').val() };
        zenodoExport.creatorList.push(creator);
        $j('#add-creator').val('');
        // I'm not calling renderCreatorList() here because it will forget which checkboxes have been
        //   checked/unchecked
        $j('#creators').append(HandlebarsTemplates['zenodo/creator'](creator));
    }
};
