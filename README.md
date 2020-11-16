# Poppler AWS Lambda Layer
Build and publish an AWS Lambda Layer which provides poppler's command line tools.

## Requirements
- Docker
- Linux
- Node

## Release
A layer called `poppler-aws-lambda-layer` will be published with [Serverless Framewok](https://www.serverless.com/).

```sh
npm install
npm run release

# release option
npm run release -- --stage dev --region ap-southeast-1
```

## Usage
If you attach the layer to a lambda function, command line tools will be installed under `/opt/bin`.

```sh
/opt/bin/pdfinfo -v
```

## License
Poppler is licensed under GPL-2.0-or-later, and so is this project.
