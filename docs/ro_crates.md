# Workflow RO Crates DRAFT

*Please note* this is a draft spec and subject to change. Please leave any suggestions and comments here: https://github.com/seek4science/seek/issues/183 

{:toc}

_Workflow RO Crates_ are a specialization of [_RO Crate_](https://researchobject.github.io/ro-crate/) for packaging an 
executable workflow with all necessary documentation.

The Workflow Hub uses _Workflow RO Crates_ as an exchange format for users to upload a packaged workflow. 

## Concepts

This section uses terminology from the [RO Crate 1.0 specification](https://researchobject.github.io/ro-crate/1.0/).

### Main Workflow

The _Crate_ MUST contain a data entity of type `["File", "SoftwareSourceCode", "Workflow"]` as the _Main Workflow_.

The _Crate_ MUST refer to the _Main Workflow_ via `mainEntity`.

The _Main Workflow_ MUST refer to its type via `programmingLanguage`.

### Main Workflow CWL Description

The _Crate_ COULD contain a data entity of type `["File", "SoftwareSourceCode", "Workflow"]` as the _Main Workflow CWL Description_.

If present the _Main Workflow_ MUST refer to the _Main Workflow CWL Description_ via `subjectOf`.

### Main Workflow Diagram

The _Crate_ COULD contain a data entity of type `["File", "ImageObject", "WorkflowSketch"]` as the _Main Workflow Diagram_.

If present the _Main Workflow_ MUST refer to the _Main Workflow CWL Diagram_ via `image`.

### Crate

The _Crate_ MUST specify a `license`.

The _Crate_ SHOULD contain README.md at the root level.

The _Crate_ COULD contain a Dataset (directory) data entity of type `["Dataset"]` named "test" to hold tests.

The _Crate_ COULD contain a Dataset (directory) data entity of type `["Dataset"]` named "examples" to hold examples.

## Workflow Hub-specific Features/Requirements

### File Format

The Workflow RO Crate must be zipped, and have the file extension `.crate.zip` to be recognized by the Workflow Hub.

### Extracted Metadata

The Workflow Hub will extract and expose the following properties from the Crate entity (`./`) in `ro-crate-metadata.jsonld`:

* `name` - This will be shown as the title of the workflow.
* `description` - This will be shown as the description of the workflow. 
If it is not present, but a `README.md` file is available in the root of the crate, that will be rendered instead.
* `author` - These will be shown as "creators" of the workflow.
* `license` - See below.
* `keywords` - These will be shown as "tags", and can be filtered over.

If the _Main Workflow CWL Description_ is present it will be parsed and the inputs, outputs and steps will be listed on the workflow's page in the Hub.

If the _Main Workflow Diagram_ is present, it will also be rendered on the page.

### Supported Workflow Types

The Workflow Hub currently supports CWL, Galaxy, KNIME and Nextflow workflow types.

To ensure compatibility, please include one of the following in the RO Crate metadata, and refer to it from the _Main Workflow_'s `programmingLanguage`.

#### CWL
```json
{
  "@id": "#cwl",
  "@type": "ComputerLanguage",
  "name": "Common Workflow Language",
  "alternateName": "CWL",
  "identifier": {
    "@id": "https://w3id.org/cwl/v1.0/"
  },
  "url": {
    "@id": "https://www.commonwl.org/"
  }
}
```

#### Galaxy
```json
{
  "@id": "#galaxy",
  "@type": "ComputerLanguage",
  "name": "Galaxy",
  "identifier": {
    "@id": "https://galaxyproject.org/"
  },
  "url": {
    "@id": "https://galaxyproject.org/"
  }
}
```
#### KNIME
```json
{
  "@id": "#knime",
  "@type": "ComputerLanguage",
  "name": "KNIME",
  "identifier": {
    "@id": "https://www.knime.com/"
  },
  "url": {
    "@id": "https://www.knime.com/"
  }
}
```
#### Nextflow
```json
{
  "@id": "#nextflow",
  "@type": "ComputerLanguage",
  "name": "Nextflow",
  "identifier": {
    "@id": "https://www.nextflow.io/"
  },
  "url": {
    "@id": "https://www.nextflow.io/"
  }
}
```

### Supported Licenses

Although the Crate's `license` field should be a URL, the Workflow Hub currently accepts a string of one of the following values (on the left):

* `AFL-3.0` - [Academic Free License 3.0](https://opensource.org/licenses/AFL-3.0)
* `APL-1.0` - [Adaptive Public License 1.0](https://opensource.org/licenses/APL-1.0)
* `Apache-1.1` - [Apache Software License 1.1](https://opensource.org/licenses/Apache-1.1)
* `Apache-2.0` - [Apache Software License 2.0](https://opensource.org/licenses/Apache-2.0)
* `APSL-2.0` - [Apple Public Source License 2.0](https://opensource.org/licenses/APSL-2.0)
* `Artistic-2.0` - [Artistic License 2.0](https://opensource.org/licenses/Artistic-2.0)
* `AAL` - [Attribution Assurance Licenses](https://opensource.org/licenses/AAL)
* `BSD-2-Clause` - [BSD 2-Clause "Simplified" or "FreeBSD" License (BSD-2-Clause)](https://opensource.org/licenses/BSD-2-Clause)
* `BSD-3-Clause` - [BSD 3-Clause "New" or "Revised" License (BSD-3-Clause)](https://opensource.org/licenses/BSD-3-Clause)
* `BitTorrent-1.1` - [BitTorrent Open Source License 1.1](https://spdx.org/licenses/BitTorrent-1.1)
* `BSL-1.0` - [Boost Software License 1.0](https://opensource.org/licenses/BSL-1.0)
* `CC0-1.0` - [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)
* `CNRI-Python` - [CNRI Python License](https://opensource.org/licenses/CNRI-Python)
* `CUA-OPL-1.0` - [CUA Office Public License 1.0](https://opensource.org/licenses/CUA-OPL-1.0)
* `CECILL-2.1` - [CeCILL License 2.1](https://opensource.org/licenses/CECILL-2.1)
* `CDDL-1.0` - [Common Development and Distribution License 1.0](https://opensource.org/licenses/CDDL-1.0)
* `CPAL-1.0` - [Common Public Attribution License 1.0](https://opensource.org/licenses/CPAL-1.0)
* `CATOSL-1.1` - [Computer Associates Trusted Open Source License 1.1 (CATOSL-1.1)](https://opensource.org/licenses/CATOSL-1.1)
* `EUDatagrid` - [EU DataGrid Software License](https://opensource.org/licenses/EUDatagrid)
* `EPL-1.0` - [Eclipse Public License 1.0](https://opensource.org/licenses/EPL-1.0)
* `ECL-2.0` - [Educational Community License 2.0](https://opensource.org/licenses/ECL-2.0)
* `EFL-2.0` - [Eiffel Forum License 2.0](https://opensource.org/licenses/EFL-2.0)
* `Entessa` - [Entessa Public License](https://opensource.org/licenses/Entessa)
* `EUPL-1.1` - [European Union Public License 1.1](https://opensource.org/licenses/EUPL-1.1)
* `Fair` - [Fair License](https://opensource.org/licenses/Fair)
* `Frameworx-1.0` - [Frameworx License 1.0](https://opensource.org/licenses/Frameworx-1.0)
* `AGPL-3.0` - [GNU Affero General Public License v3](https://opensource.org/licenses/AGPL-3.0)
* `GPL-2.0` - [GNU General Public License 2.0](https://opensource.org/licenses/GPL-2.0)
* `GPL-3.0` - [GNU General Public License 3.0](https://opensource.org/licenses/GPL-3.0)
* `LGPL-2.1` - [GNU Lesser General Public License 2.1](https://opensource.org/licenses/LGPL-2.1)
* `LGPL-3.0` - [GNU Lesser General Public License 3.0](https://opensource.org/licenses/LGPL-3.0)
* `HPND` - [Historical Permission Notice and Disclaimer](https://opensource.org/licenses/HPND)
* `IPL-1.0` - [IBM Public License 1.0](https://opensource.org/licenses/IPL-1.0)
* `IPA` - [IPA Font License](https://opensource.org/licenses/IPA)
* `ISC` - [ISC License](https://opensource.org/licenses/ISC)
* `Intel` - [Intel Open Source License](https://opensource.org/licenses/Intel)
* `LPPL-1.3c` - [LaTeX Project Public License 1.3c](https://opensource.org/licenses/LPPL-1.3c)
* `LPL-1.0` - [Lucent Public License ("Plan9") 1.0](https://opensource.org/licenses/LPL-1.0)
* `LPL-1.02` - [Lucent Public License 1.02](https://opensource.org/licenses/LPL-1.02)
* `MIT` - [MIT License](https://opensource.org/licenses/MIT)
* `mitre` - [MITRE Collaborative Virtual Workspace License (CVW License)](https://opensource.org/licenses/CVW)
* `MS-PL` - [Microsoft Public License](https://opensource.org/licenses/MS-PL)
* `MS-RL` - [Microsoft Reciprocal License](https://opensource.org/licenses/MS-RL)
* `MirOS` - [MirOS Licence](https://opensource.org/licenses/MirOS)
* `Motosoto` - [Motosoto License](https://opensource.org/licenses/Motosoto)
* `MPL-1.0` - [Mozilla Public License 1.0](https://opensource.org/licenses/MPL-1.0)
* `MPL-1.1` - [Mozilla Public License 1.1](https://opensource.org/licenses/MPL-1.1)
* `MPL-2.0` - [Mozilla Public License 2.0](https://opensource.org/licenses/MPL-2.0)
* `Multics` - [Multics License](https://opensource.org/licenses/Multics)
* `NASA-1.3` - [NASA Open Source Agreement 1.3](https://opensource.org/licenses/NASA-1.3)
* `NTP` - [NTP License](https://opensource.org/licenses/NTP)
* `Naumen` - [Naumen Public License](https://opensource.org/licenses/Naumen)
* `NGPL` - [Nethack General Public License](https://opensource.org/licenses/NGPL)
* `Nokia` - [Nokia Open Source License](https://opensource.org/licenses/Nokia)
* `NPOSL-3.0` - [Non-Profit Open Software License 3.0](https://opensource.org/licenses/NPOSL-3.0)
* `OCLC-2.0` - [OCLC Research Public License 2.0](https://opensource.org/licenses/OCLC-2.0)
* `OFL-1.1` - [Open Font License 1.1](https://opensource.org/licenses/OFL-1.1)
* `OGL-UK-1.0` - [Open Government Licence 1.0 (United Kingdom)](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/1/)
* `OGL-UK-2.0` - [Open Government Licence 2.0 (United Kingdom)](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/2/)
* `OGL-UK-3.0` - [Open Government Licence 3.0 (United Kingdom)](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/)
* `OGTSL` - [Open Group Test Suite License](https://opensource.org/licenses/OGTSL)
* `OSL-3.0` - [Open Software License 3.0](https://opensource.org/licenses/OSL-3.0)
* `PHP-3.0` - [PHP License 3.0](https://opensource.org/licenses/PHP-3.0)
* `PostgreSQL` - [PostgreSQL License](https://opensource.org/licenses/PostgreSQL)
* `Python-2.0` - [Python License 2.0](https://opensource.org/licenses/Python-2.0)
* `QPL-1.0` - [Q Public License 1.0](https://opensource.org/licenses/QPL-1.0)
* `RPSL-1.0` - [RealNetworks Public Source License 1.0](https://opensource.org/licenses/RPSL-1.0)
* `RPL-1.5` - [Reciprocal Public License 1.5](https://opensource.org/licenses/RPL-1.5)
* `RSCPL` - [Ricoh Source Code Public License](https://opensource.org/licenses/RSCPL)
* `SimPL-2.0` - [Simple Public License 2.0](https://opensource.org/licenses/SimPL-2.0)
* `Sleepycat` - [Sleepycat License](https://opensource.org/licenses/Sleepycat)
* `SISSL` - [Sun Industry Standards Source License 1.1](https://opensource.org/licenses/SISSL)
* `SPL-1.0` - [Sun Public License 1.0](https://opensource.org/licenses/SPL-1.0)
* `Watcom-1.0` - [Sybase Open Watcom Public License 1.0](https://opensource.org/licenses/Watcom-1.0)
* `NCSA` - [University of Illinois/NCSA Open Source License](https://opensource.org/licenses/NCSA)
* `Unlicense` - [Unlicense](https://unlicense.org/)
* `VSL-1.0` - [Vovida Software License 1.0](https://opensource.org/licenses/VSL-1.0)
* `W3C` - [W3C License](https://opensource.org/licenses/W3C)
* `Xnet` - [X.Net License](https://opensource.org/licenses/Xnet)
* `ZPL-2.0` - [Zope Public License 2.0](https://opensource.org/licenses/ZPL-2.0)
* `WXwindows` - [wxWindows Library License](https://opensource.org/licenses/WXwindows)
* `Zlib` - [zlib/libpng license](https://opensource.org/licenses/Zlib)
* `notspecified` - [No license - no permission to use unless the owner grants a licence](https://choosealicense.com/no-permission/)

### ro-crate-metadata.jsonld Example
A minimal example of _Workflow RO Crate_ metadata, containing a CWL workflow, an SVG diagram of that workflow and a README file.

```json
{
  "@context": "https://w3id.org/ro/crate/1.0/context",
  "@graph": [
    {
      "@id": "ro-crate-metadata.jsonld",
      "@type": "CreativeWork",
      "about": {
        "@id": "./"
      }
    },
    {
      "@id": "ro-crate-preview.html",
      "@type": "CreativeWork",
      "about": {
        "@id": "./"
      }
    },
    {
      "@id": "./",
      "@type": "Dataset",
      "name": "Example Workflow",
      "description": "An example workflow RO Crate",
      "license": "Apache-2.0",
      "mainEntity": {
        "@id": "example_workflow.cwl"
      },
      "hasPart": [
        {
          "@id": "example_workflow.cwl"
        },
        {
          "@id": "diagram.svg"
        },
        {
          "@id": "README.md"
        }
      ]
    },
    {
      "@id": "example_workflow.cwl",
      "@type": [
        "File",
        "SoftwareSourceCode",
        "Workflow"
      ],
      "programmingLanguage": {
        "@id": "#cwl"
      },
      "name": "Example Workflow",
      "image": {
        "@id": "diagram.svg"
      }
    },
    {
      "@id": "diagram.svg",
      "name": "Example Workflow Diagram",
      "@type": [
        "File",
        "ImageObject",
        "WorkflowSketch"
      ]
    },
    {
      "@id": "README.md",
      "@type": "File"
    },
    {
      "@id": "#cwl",
      "@type": "ComputerLanguage",
      "name": "Common Workflow Language",
      "alternateName": "CWL",
      "identifier": {
        "@id": "https://w3id.org/cwl/v1.0/"
      },
      "url": {
        "@id": "https://www.commonwl.org/"
      }
    }
  ]
}
```
