class CustomDataTypeGVK extends CustomDataTypeWithCommonsAsPlugin

    #######################################################################  
    # return the prefix for localization for this data type.  
    # Note: This function is supposed to be deprecated, but is still used   
    # internally and has to be used here as a workaround because the   
    # default generates incorrect prefixes for camelCase class names 
    getL10NPrefix: ->
      'custom.data.type.gvk'

    #######################################################################
    # return name of plugin
    getCustomDataTypeName: ->
      "custom:base.custom-data-type-gvk.gvk"

    #######################################################################
    # return name (l10n) of plugin
    getCustomDataTypeNameLocalized: ->
      $$("custom.data.type.gvk.name")

    #######################################################################
    # return plugin name
    name: (opts = {}) ->
      if ! @ColumnSchema
        return "noNameSet"
      else
        return @ColumnSchema?.name


    #######################################################################
    # returns the databaseLanguages
    getDatabaseLanguages: () ->
      databaseLanguages = ez5.loca.getLanguageControl().getLanguages().slice()
      return databaseLanguages


    #######################################################################
    # returns name of the needed or configures language for the labels of api-requests
    getActiveFrontendLanguage: () ->
      desiredLanguage = ez5.loca.getLanguage()
      desiredLanguage = desiredLanguage.split('-')
      language = desiredLanguage[0]

      return language

    #######################################################################
    # configure used facet
    getFacet: (opts) ->
      opts.field = @
      new CustomDataTypek10plusFacet(opts)

    #######################################################################
    # get the configured databases from datamodell
    __getDatabasesFromDatamodell: () ->
       databases = []

       databasesFromSchema = @getCustomSchemaSettings().database?.value.split('|')
       if databasesFromSchema?.length > 0
         databases = databasesFromSchema

       databasesFromMask = @getCustomMaskSettings().database_overwrite?.value.split('|')
       if databasesFromMask?.length > 0
         databases = databasesFromMask

       databases

    #######################################################################
    # handle suggestions-menu
    __updateSuggestionsMenu: (cdata, cdata_form, searchstring, input, suggest_Menu, searchsuggest_xhr, layout, opts) ->
        that = @

        delayMillisseconds = 200

        setTimeout ( ->

            gvk_searchterm = searchstring
            gvk_countSuggestions = 20
            gvk_database = ''

            if (cdata_form)
              gvk_searchterm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()
              gvk_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()
              gvk_database = ''
              if cdata_form.getFieldsByName("gndSelectDatabase").length > 0
                if cdata_form.getFieldsByName("gndSelectDatabase")[0].getValue()
                  gvk_database = '&database=' + cdata_form.getFieldsByName("gndSelectDatabase")[0].getValue()

            # if no database is selected from dropdown (searchbar-mode), take the first one
            if ! gvk_database
             databases = that.__getDatabasesFromDatamodell()
             if databases.length > 0
               databaseParts = databases[0].split('=')
               if databaseParts.length == 2
                if databaseParts[1]
                  gvk_database = '&database=' + databaseParts[1];

            if gvk_searchterm.length == 0
               return

            # run autocomplete-search via xhr
            if searchsuggest_xhr.xhr != undefined
               # abort eventually running request
               searchsuggest_xhr.xhr.abort()

            # start new request
            # build searchurl
            url = 'https://ws.gbv.de/suggest/csl2/?query=pica.all=' + gvk_searchterm + '&citationstyle=ieee&language=de&count=' + gvk_countSuggestions + gvk_database
            searchsuggest_xhr.xhr = new (CUI.XHR)(url: url)
            searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

               # create new menu with suggestions
               menu_items = []
               # the actual Featureclass
               actualFclass = ''
               for suggestion, key in data[1]
                   do(key) ->
                       if (actualFclass == '' || actualFclass != data[2][key])
                           actualFclass = data[2][key]
                           item =
                               divider: true
                           menu_items.push item
                           item =
                               label: actualFclass
                           menu_items.push item
                           item =
                               divider: true
                           menu_items.push item
                       item =
                           text: suggestion
                           #center: new CUI.Label(text: suggestion, multiline: true)
                           value: data[3][key]

                       menu_items.push item

               # set new items to menu
               itemList =
                   onClick: (ev2, btn) ->
                       # lock in save data
                       cdata.conceptURI = btn.getOpt("value")
                       cdata.conceptName = btn.getText()
                       # save conceptSource
                       cdata.conceptSource = (cdata.conceptURI.match(/document\/(.*):ppn/) || [])[1] || null
                       # save _fulltext
                       cdata._fulltext = k10plusUtilities.getFullTextFromString(cdata.conceptURI, cdata.conceptName, that.getDatabaseLanguages())
                       # save _standard
                       cdata._standard = k10plusUtilities.getStandardFromString(cdata.conceptName, that.getDatabaseLanguages())
                       # save facet
                       cdata.facetTerm = k10plusUtilities.getFacetTerm(cdata.conceptURI, cdata.conceptName, that.getDatabaseLanguages())
                       # save frontendlanguage
                       cdata.frontendLanguage = that.getActiveFrontendLanguage()
                       # update the layout in form
                       that.__updateResult(cdata, layout, opts)
                       # hide suggest-menu
                       suggest_Menu.hide()
                       # close popover
                       if that.popover
                        that.popover.hide()
                   items: menu_items

               # if no hits set "empty" message to menu
               if itemList.items.length == 0
                   itemList =
                       items: [
                           text: $$('custom.data.type.gvk.modal.form.text.no_hit')
                           value: undefined
                       ]

               suggest_Menu.setItemList(itemList)

               suggest_Menu.show()

            )
        ), delayMillisseconds



    #######################################################################
    # create form
    __getEditorFields: (cdata) ->

        databases = @__getDatabasesFromDatamodell()

        # if no database is configured, dont show that dropdown and use default from webservice
        databaseOptions = []
        if Array.isArray databases
          if databases.length > 0
            for database in databases
             databaseConfig = database.split('=')
             if databaseConfig.length == 2
               option = (
                  value: databaseConfig[1]
                  text: databaseConfig[0]
                )
               databaseOptions.push option
        fields = [
            {
                type: CUI.Select
                class: "commonPlugin_Select"
                undo_and_changed_support: false
                form:
                    label: $$('custom.data.type.gvk.modal.form.text.count')
                options: [
                    (
                        value: 10
                        text: '10 ' + $$('custom.data.type.gvk.modal.form.text.count_short')
                    )
                    (
                        value: 20
                        text: '20 ' + $$('custom.data.type.gvk.modal.form.text.count_short')
                    )
                    (
                        value: 50
                        text: '50 ' + $$('custom.data.type.gvk.modal.form.text.count_short')
                    )
                    (
                        value: 100
                        text: '100 ' + $$('custom.data.type.gvk.modal.form.text.count_short')
                    )
                ]
                name: 'countOfSuggestions'
            }
            {
                type: CUI.Input
                class: "commonPlugin_Input"
                undo_and_changed_support: false
                form:
                    label: $$("custom.data.type.gvk.modal.form.text.searchbar")
                placeholder: $$("custom.data.type.gvk.modal.form.text.searchbar.placeholder")
                name: "searchbarInput"
            }]

        if databaseOptions.length > 0
           databaseSelect = {
            type: CUI.Select
            undo_and_changed_support: false
            form:
                label: $$('custom.data.type.gnd.modal.form.text.database')
            options: databaseOptions
            name: 'gndSelectDatabase'
            class: 'commonPlugin_Select'
           }
           fields.unshift(databaseSelect)

        fields


    #######################################################################
    # renders the "result" in original form (outside popover)
    __renderButtonByData: (cdata) ->

       # when status is empty or invalid --> message

       switch @getDataStatus(cdata)
           when "empty"
               return new CUI.EmptyLabel(text: $$("custom.data.type.gvk.edit.no_gvk")).DOM
           when "invalid"
               return new CUI.EmptyLabel(text: $$("custom.data.type.gvk.edit.no_valid_gvk")).DOM

       # if status is ok
       conceptURI = CUI.parseLocation(cdata.conceptURI).url

       # output Button with Name of picked entry and URI
       new CUI.HorizontalLayout
        maximize: false
        left:
          content:
            new CUI.Label
             centered: false
             multiline: true
             text: cdata.conceptName
        center:
          content:
            # output Button with Name of picked Entry and Url to the Source
            new CUI.ButtonHref
             appearance: "link"
             href: conceptURI
             target: "_blank"
             tooltip:
               markdown: true
             text: " "
        right: null
       .DOM


    #######################################################################
    # zeige die gewählten Optionen im Datenmodell unter dem Button an
    getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
       tags = []

       if custom_settings.database?.value
        tags.push $$("custom.data.type.gvk.name") + ': ' + custom_settings.database.value
       else
        tags.push $$("custom.data.type.gvk.setting.schema.no_database")

       tags

CustomDataType.register(CustomDataTypeGVK)
