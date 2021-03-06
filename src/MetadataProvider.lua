return {
    metadataFieldsForPhotos = {
        {
            id = 'picasastar',
            title = 'Star',
            dataType = 'enum',
            searchable = true,
            readonly = true,
            browsable = true,
            values = { { value = 'true', title = 'Yes', }, { value = 'false', title = 'No' }, },
        }, {
            id = 'picasacaption',
            title = 'Caption',
            dataType = 'string',
            searchable = true,
            readonly = true,
            browsable = true,
        }, {
            id = 'picasakeywords',
            title = 'Keywords',
            dataType = 'string',
            searchable = true,
            readonly = true,
            browsable = true,
        }, {
            id = 'picasarotate',
            title = 'Rotate',
            dataType = 'enum',
            searchable = true,
            readonly = true,
            browsable = true,
            values = { { value = 90, title = '90º', }, { value = 180, title = '180º' }, }, { value = 270, title = '270º', }
        }, {
            id = 'picasaenhance',
            title = 'I am feeling looky enhance',
            dataType = 'enum',
            searchable = true,
            readonly = true,
            browsable = true,
            values = { { value = 'true', title = 'Yes', }, { value = 'false', title = 'No' }, },
        }, {
            id = 'picasaautolight',
            title = 'Autolight',
            dataType = 'enum',
            searchable = true,
            readonly = true,
            browsable = true,
            values = { { value = 'true', title = 'Yes', }, { value = 'false', title = 'No' }, },
        }, {
            id = 'picasaautocolor',
            title = 'Autocolor',
            dataType = 'enum',
            searchable = true,
            readonly = true,
            browsable = true,
            values = { { value = 'true', title = 'Yes', }, { value = 'false', title = 'No' }, },
        }, {
            id = 'picasablackWhite',
            title = 'Black & white',
            dataType = 'enum',
            searchable = true,
            readonly = true,
            browsable = true,
            values = { { value = 'true', title = 'Yes', }, { value = 'false', title = 'No' }, },
        }, {
            id = 'picasatilt',
            title = 'Tilt scale & angle',
            dataType = 'enum',
            searchable = true,
            readonly = true,
            browsable = true,
            values = { { value = 'true', title = 'Yes', }, { value = 'false', title = 'No' }, },
        }, {
            id = 'picasatiltangle',
            title = 'Tilt angle',
            dataType = 'string',
            readonly = true,
            --            searchable = true,
        }, {
            id = 'picasatiltscale',
            title = 'Tilt scale',
            dataType = 'string',
            readonly = true,
            --            searchable = true,
        }, {
            id = 'picasacrop',
            title = 'Crop',
            dataType = 'enum',
            searchable = true,
            readonly = true,
            browsable = true,
            values = { { value = 'true', title = 'Yes', }, { value = 'false', title = 'No' }, },
        }, {
            id = 'picasacropleft',
            title = 'Left crop',
            dataType = 'string',
            readonly = true,
            --            searchable = true,
        }, {
            id = 'picasa',
            title = 'Right crop',
            dataType = 'string',
            readonly = true,
            --            searchable = true,
        }, {
            id = 'picasacroptop',
            title = 'Top crop',
            dataType = 'string',
            readonly = true,
            --            searchable = true,
        }, {
            id = 'picasacropbottom',
            title = 'Bottom crop',
            dataType = 'string',
            readonly = true,
            --            searchable = true,
        },
    },
    schemaVersion = 1,
}