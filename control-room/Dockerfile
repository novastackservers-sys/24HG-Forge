FROM oven/bun:1-alpine

WORKDIR /app

COPY package.json bun.lock* ./
RUN bun install --production

COPY . .

RUN mkdir -p data

ENV PORT=3847
ENV ISO_DIR=/srv/landing-page/iso
ENV LANDING_DIR=/srv/landing-page

EXPOSE 3847

CMD ["bun", "run", "server.ts"]
