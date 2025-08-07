FROM maven:3.9-eclipse-temurin-17 AS js-builder

WORKDIR /workspace

# 复制Maven配置文件（使用阿里云镜像加速）
COPY settings-china.xml /usr/share/maven/ref/settings-docker.xml

# 复制整个项目（Maven需要完整的模块结构）
COPY . /workspace/

# 配置Maven环境变量，内存优化
ENV MAVEN_OPTS="-Dmaven.repo.local=/usr/share/maven/ref/repository -Xmx512m -XX:MaxMetaspaceSize=128m -XX:+UseG1GC"
RUN chmod -R 755 /workspace

# 分步骤构建：先构建js-parent，再构建themes-vendor
RUN mvn -s /usr/share/maven/ref/settings-docker.xml install -pl js -DskipTests \
    -Dmaven.wagon.http.connectTimeout=120000 \
    -Dmaven.wagon.http.readTimeout=120000 \
    --batch-mode --no-transfer-progress \
    -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn || \
    (echo "Retrying with manual pnpm link..." && \
     cd /workspace/js && \
     [ -d node/node_modules/pnpm/bin ] && ln -sf /workspace/js/node/node_modules/pnpm/bin/pnpm.cjs /workspace/js/node/pnpm || true && \
     mvn -s /usr/share/maven/ref/settings-docker.xml install -pl js/themes-vendor -am -DskipTests \
     --batch-mode --no-transfer-progress)

FROM quay.io/keycloak/keycloak:latest AS theme-builder

# 复制主题文件
COPY themes/src/main/resources/theme/ /opt/keycloak/themes/
COPY themes/src/main/resources-community/theme/ /opt/keycloak/themes/

# 从js构建阶段复制vendor文件
COPY --from=js-builder /workspace/js/themes-vendor/target/classes/theme/ /opt/keycloak/themes/

# 运行Keycloak构建优化
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:latest

# 复制优化后的Keycloak配置
COPY --from=theme-builder /opt/keycloak/ /opt/keycloak/

# 设置自定义主题
ENV KC_THEME=keycloak.v2

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]