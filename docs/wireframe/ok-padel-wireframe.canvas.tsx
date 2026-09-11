import {
  Button,
  Callout,
  Card,
  CardBody,
  CardHeader,
  Divider,
  Grid,
  H1,
  H2,
  Pill,
  Row,
  Spacer,
  Stack,
  Stat,
  Table,
  Text,
  useCanvasState,
  useHostTheme,
} from "cursor/canvas";

type Screen =
  | "home"
  | "login"
  | "courts"
  | "detail"
  | "reservations"
  | "profile"
  | "admin";

const SCREENS: { id: Screen; label: string }[] = [
  { id: "home", label: "Home" },
  { id: "login", label: "Login" },
  { id: "courts", label: "Canchas" },
  { id: "detail", label: "Reservar" },
  { id: "reservations", label: "Mis reservas" },
  { id: "profile", label: "Perfil" },
  { id: "admin", label: "Admin" },
];

export default function OkPadelWireframe() {
  const [screen, setScreen] = useCanvasState<Screen>("screen", "home");

  return (
    <Stack gap={20}>
      <Stack gap={6}>
        <H1>Ok Padel — wireframe</H1>
        <Text tone="secondary">
          Prototipo de baja fidelidad para TP Prog IV. Clickeá una pantalla
          para recorrer el flujo de reserva de canchas.
        </Text>
      </Stack>

      <Row gap={8} wrap>
        {SCREENS.map((item) => (
          <span key={item.id}>
            <Button
              variant={screen === item.id ? "primary" : "secondary"}
              onClick={() => setScreen(item.id)}
            >
              {item.label}
            </Button>
          </span>
        ))}
      </Row>

      {screen === "home" && <HomeScreen onOpen={setScreen} />}
      {screen === "login" && <LoginScreen onOpen={setScreen} />}
      {screen === "courts" && <CourtsScreen onOpen={setScreen} />}
      {screen === "detail" && <DetailScreen onOpen={setScreen} />}
      {screen === "reservations" && <ReservationsScreen onOpen={setScreen} />}
      {screen === "profile" && <ProfileScreen onOpen={setScreen} />}
      {screen === "admin" && <AdminScreen onOpen={setScreen} />}

      <Divider />

      <H2>Flujo</H2>
      <Grid columns={4} gap={12}>
        <Stat value="Visitante" label="Home → login / registro" />
        <Stat value="Jugador" label="Canchas → turno → confirmar" />
        <Stat value="Reservas" label="Listar, cancelar, historial" />
        <Stat value="Admin" label="ABM canchas y usuarios" />
      </Grid>
    </Stack>
  );
}

function HomeScreen({ onOpen }: { onOpen: (s: Screen) => void }) {
  return (
    <Stack gap={12}>
      <BrowserFrame
        url="okpadel.local/"
        nav={
          <GuestNav
            active="home"
            onLogin={() => onOpen("login")}
            onCourts={() => onOpen("courts")}
          />
        }
      >
        <Stack gap={16}>
          <Stack gap={8}>
            <H2>Reservá tu cancha de pádel</H2>
            <Text tone="secondary">
              Turnos de 90 minutos · indoor y outdoor · confirmación por mail
            </Text>
            <Row>
              <Button variant="primary" onClick={() => onOpen("courts")}>
                Ver canchas disponibles
              </Button>
            </Row>
          </Stack>
          <PhotoBox label="Imagen hero del club" height={88} />
          <Grid columns={3} gap={12}>
            <CourtCard
              name="Cancha 1"
              meta="Indoor · Césped · $8000"
              onReserve={() => onOpen("detail")}
            />
            <CourtCard
              name="Cancha 2"
              meta="Outdoor · Cemento · $6000"
              onReserve={() => onOpen("detail")}
            />
            <CourtCard
              name="Cancha 3"
              meta="Indoor · Césped · $8500"
              onReserve={() => onOpen("detail")}
            />
          </Grid>
        </Stack>
      </BrowserFrame>
      <Callout tone="info" title="Home">
        Landing pública. CTA principal lleva al listado. Sin sesión no se
        confirma reserva: al elegir turno pide login.
      </Callout>
    </Stack>
  );
}

function LoginScreen({ onOpen }: { onOpen: (s: Screen) => void }) {
  return (
    <Stack gap={12}>
      <BrowserFrame url="okpadel.local/users/sign_in" nav={<GuestNav />}>
        <Row justify="center">
          <Card style={{ width: 360 }}>
            <CardHeader>Iniciar sesión</CardHeader>
            <CardBody>
              <Stack gap={12}>
                <Field label="Email" placeholder="juan@mail.com" />
                <Field label="Password" placeholder="••••••••" />
                <Text size="small" tone="secondary">
                  Recordarme
                </Text>
                <Row>
                  <Button variant="primary" onClick={() => onOpen("courts")}>
                    Entrar
                  </Button>
                </Row>
                <Text size="small" tone="secondary">
                  ¿Olvidaste tu contraseña? · ¿No tenés cuenta? Registrarse
                </Text>
              </Stack>
            </CardBody>
          </Card>
        </Row>
      </BrowserFrame>
      <Callout tone="info" title="Login (Devise)">
        Email + password. Registro aparte: nombre, email, password, confirmar.
        Sesión requerida para confirmar un turno.
      </Callout>
    </Stack>
  );
}

function CourtsScreen({ onOpen }: { onOpen: (s: Screen) => void }) {
  return (
    <Stack gap={12}>
      <BrowserFrame
        url="okpadel.local/canchas"
        nav={<AppNav active="courts" onOpen={onOpen} />}
      >
        <Stack gap={14}>
          <H2>Canchas</H2>
          <Row gap={8} wrap>
            <Pill>Tipo: todas</Pill>
            <Pill>Cubierta: todas</Pill>
            <Pill>Fecha: 10/09/2026</Pill>
            <Button variant="secondary">Buscar</Button>
          </Row>
          <Grid columns={3} gap={12}>
            <CourtCard
              name="Cancha 1"
              meta="Indoor · Césped · $8000 / 90 min"
              onReserve={() => onOpen("detail")}
            />
            <CourtCard
              name="Cancha 2"
              meta="Outdoor · Cemento · $6000 / 90 min"
              onReserve={() => onOpen("detail")}
            />
            <CourtCard
              name="Cancha 3"
              meta="Indoor · Césped · $8500 / 90 min"
              onReserve={() => onOpen("detail")}
            />
          </Grid>
          <Text size="small" tone="tertiary">
            Paginación (Pagy): 1  2  3
          </Text>
        </Stack>
      </BrowserFrame>
      <Callout tone="info" title="Listado">
        Cards con foto (Active Storage), tipo, precio y CTA. Filtros por tipo,
        cubierta y fecha. Paginado con Pagy.
      </Callout>
    </Stack>
  );
}

function DetailScreen({ onOpen }: { onOpen: (s: Screen) => void }) {
  const slots = [
    { t: "08:00", s: "libre" },
    { t: "09:30", s: "ocupado" },
    { t: "11:00", s: "libre" },
    { t: "12:30", s: "libre" },
    { t: "14:00", s: "ocupado" },
    { t: "15:30", s: "libre" },
    { t: "17:00", s: "sel" },
    { t: "18:30", s: "libre" },
    { t: "20:00", s: "ocupado" },
    { t: "21:30", s: "libre" },
    { t: "23:00", s: "libre" },
  ] as const;

  return (
    <Stack gap={12}>
      <BrowserFrame
        url="okpadel.local/canchas/1"
        nav={<AppNav active="courts" onOpen={onOpen} />}
      >
        <Stack gap={14}>
          <Row>
            <Button variant="ghost" onClick={() => onOpen("courts")}>
              Volver a canchas
            </Button>
          </Row>
          <Grid columns="1.1fr 1fr" gap={16}>
            <Stack gap={10}>
              <PhotoBox label="Foto cancha 1" height={160} />
              <H2>Cancha 1</H2>
              <Text tone="secondary">Indoor · Césped sintético</Text>
              <Row gap={8}>
                <Pill active>Iluminación</Pill>
                <Pill>$8000 / 90 min</Pill>
              </Row>
            </Stack>
            <Stack gap={10}>
              <Text weight="semibold">Elegí fecha</Text>
              <Pill active>10/09/2026</Pill>
              <Text weight="semibold">Turnos</Text>
              <Grid columns={4} gap={8}>
                {slots.map((slot) => (
                  <div key={slot.t}>
                    <Slot time={slot.t} state={slot.s} />
                  </div>
                ))}
              </Grid>
              <Text size="small">Turno seleccionado: 17:00 – 18:30</Text>
              <Row>
                <Button
                  variant="primary"
                  onClick={() => onOpen("reservations")}
                >
                  Confirmar reserva
                </Button>
              </Row>
            </Stack>
          </Grid>
        </Stack>
      </BrowserFrame>
      <Callout tone="neutral" title="Pantalla clave">
        Grilla de turnos de 90 min. Ocupado no se clickea. Confirmar genera
        reserva y envía mail (letter_opener en desarrollo).
      </Callout>
    </Stack>
  );
}

function ReservationsScreen({ onOpen }: { onOpen: (s: Screen) => void }) {
  return (
    <Stack gap={12}>
      <BrowserFrame
        url="okpadel.local/reservas"
        nav={<AppNav active="reservations" onOpen={onOpen} />}
      >
        <Stack gap={12}>
          <H2>Mis reservas</H2>
          <Row gap={8}>
            <Pill active>Próximas</Pill>
            <Pill>Historial</Pill>
          </Row>
          <Table
            headers={["Fecha", "Cancha", "Horario", "Estado", "Acciones"]}
            rows={[
              ["10/09", "Cancha 1", "17:00–18:30", "Confirmada", "Cancelar"],
              ["12/09", "Cancha 3", "20:00–21:30", "Confirmada", "Cancelar"],
              ["01/09", "Cancha 2", "09:30–11:00", "Jugada", "—"],
            ]}
            rowTone={["success", "success", "neutral"]}
            striped
          />
        </Stack>
      </BrowserFrame>
      <Callout tone="info" title="Mis reservas">
        El jugador ve solo las suyas. Cancelar con regla de anticipación
        (a definir en el enunciado). Historial de partidos jugados.
      </Callout>
    </Stack>
  );
}

function ProfileScreen({ onOpen }: { onOpen: (s: Screen) => void }) {
  return (
    <Stack gap={12}>
      <BrowserFrame
        url="okpadel.local/perfil"
        nav={<AppNav active="profile" onOpen={onOpen} />}
      >
        <Card style={{ maxWidth: 420 }}>
          <CardHeader>Mi perfil</CardHeader>
          <CardBody>
            <Stack gap={12}>
              <PhotoBox label="Avatar" height={64} />
              <Field label="Nombre" placeholder="Juan Pérez" />
              <Field label="Email" placeholder="juan@mail.com" />
              <Field label="Teléfono" placeholder="11 5555-1234" />
              <Row gap={8}>
                <Button variant="primary">Guardar cambios</Button>
                <Button variant="ghost">Cambiar contraseña</Button>
              </Row>
            </Stack>
          </CardBody>
        </Card>
      </BrowserFrame>
      <Callout tone="info" title="Perfil">
        Datos de Devise + teléfono. Foto opcional con Active Storage.
      </Callout>
    </Stack>
  );
}

function AdminScreen({ onOpen }: { onOpen: (s: Screen) => void }) {
  return (
    <Stack gap={12}>
      <BrowserFrame
        url="okpadel.local/admin/canchas"
        nav={
          <Row gap={12} align="center">
            <Text weight="semibold" as="span">
              ADMIN
            </Text>
            <Pill active>Canchas</Pill>
            <Text size="small" tone="secondary" as="span">
              Usuarios
            </Text>
            <Text size="small" tone="secondary" as="span">
              Reservas
            </Text>
            <Spacer />
            <Button variant="ghost" onClick={() => onOpen("home")}>
              Volver al sitio
            </Button>
          </Row>
        }
      >
        <Stack gap={12}>
          <Row align="center">
            <H2>Canchas</H2>
            <Spacer />
            <Button variant="primary">Nueva cancha</Button>
          </Row>
          <Table
            headers={["Nombre", "Tipo", "Precio", "Estado", "Acciones"]}
            rows={[
              ["Cancha 1", "Indoor", "$8000", "Activa", "Editar · Baja"],
              ["Cancha 2", "Outdoor", "$6000", "Activa", "Editar · Baja"],
              ["Cancha 3", "Indoor", "$8500", "Activa", "Editar · Baja"],
            ]}
            striped
          />
          <Text size="small" tone="secondary">
            Form alta/edición: nombre, tipo, superficie, precio, cubierta,
            foto, activa sí/no.
          </Text>
        </Stack>
      </BrowserFrame>
      <Callout tone="warning" title="Admin">
        Rol administrador. ABM de canchas, usuarios y vista de todas las
        reservas. El jugador no ve esta sección.
      </Callout>
    </Stack>
  );
}

function BrowserFrame({
  url,
  nav,
  children,
}: {
  url: string;
  nav?: ReturnType<typeof Row>;
  children: ReturnType<typeof Stack>;
}) {
  const theme = useHostTheme();
  return (
    <div
      style={{
        border: `1px solid ${theme.stroke.secondary}`,
        background: theme.bg.elevated,
        overflow: "hidden",
      }}
    >
      <div
        style={{
          padding: "8px 12px",
          background: theme.bg.chrome,
          borderBottom: `1px solid ${theme.stroke.tertiary}`,
        }}
      >
        <Text size="small" tone="tertiary" as="span">
          {url}
        </Text>
      </div>
      {nav ? (
        <div
          style={{
            padding: "10px 14px",
            borderBottom: `1px solid ${theme.stroke.tertiary}`,
          }}
        >
          {nav}
        </div>
      ) : null}
      <div style={{ padding: 16 }}>{children}</div>
    </div>
  );
}

function GuestNav({
  active,
  onLogin,
  onCourts,
}: {
  active?: "home";
  onLogin?: () => void;
  onCourts?: () => void;
}) {
  return (
    <Row align="center" gap={12}>
      <Text weight="semibold" as="span">
        OK PADEL
      </Text>
      <Button variant={active === "home" ? "primary" : "ghost"} onClick={onCourts}>
        Canchas
      </Button>
      <Spacer />
      <Button variant="ghost" onClick={onLogin}>
        Iniciar sesión
      </Button>
      <Button variant="secondary" onClick={onLogin}>
        Registrarse
      </Button>
    </Row>
  );
}

function AppNav({
  active,
  onOpen,
}: {
  active: "courts" | "reservations" | "profile";
  onOpen: (s: Screen) => void;
}) {
  return (
    <Row align="center" gap={8}>
      <Text weight="semibold" as="span">
        OK PADEL
      </Text>
      <Button
        variant={active === "courts" ? "primary" : "ghost"}
        onClick={() => onOpen("courts")}
      >
        Canchas
      </Button>
      <Button
        variant={active === "reservations" ? "primary" : "ghost"}
        onClick={() => onOpen("reservations")}
      >
        Mis reservas
      </Button>
      <Button
        variant={active === "profile" ? "primary" : "ghost"}
        onClick={() => onOpen("profile")}
      >
        Perfil
      </Button>
      <Spacer />
      <Button variant="ghost" onClick={() => onOpen("home")}>
        Salir
      </Button>
    </Row>
  );
}

function CourtCard({
  name,
  meta,
  onReserve,
}: {
  name: string;
  meta: string;
  onReserve: () => void;
}) {
  return (
    <Card>
      <CardHeader>{name}</CardHeader>
      <CardBody>
        <Stack gap={8}>
          <PhotoBox label="Foto" height={72} />
          <Text size="small" tone="secondary">
            {meta}
          </Text>
          <Row>
            <Button variant="primary" onClick={onReserve}>
              Reservar
            </Button>
          </Row>
        </Stack>
      </CardBody>
    </Card>
  );
}

function Slot({
  time,
  state,
}: {
  time: string;
  state: "libre" | "ocupado" | "sel";
}) {
  const theme = useHostTheme();
  const bg =
    state === "sel"
      ? theme.accent.primary
      : state === "ocupado"
        ? theme.fill.tertiary
        : theme.fill.secondary;
  const color = state === "sel" ? theme.text.onAccent : theme.text.primary;
  return (
    <div
      style={{
        padding: "8px 6px",
        background: bg,
        border: `1px solid ${theme.stroke.tertiary}`,
        textAlign: "center",
      }}
    >
      <div style={{ color, fontSize: 11, fontWeight: 600 }}>{time}</div>
      <div
        style={{
          color: state === "sel" ? theme.text.onAccent : theme.text.tertiary,
          fontSize: 10,
        }}
      >
        {state === "sel" ? "Elegido" : state === "ocupado" ? "Ocupado" : "Libre"}
      </div>
    </div>
  );
}

function Field({ label, placeholder }: { label: string; placeholder: string }) {
  const theme = useHostTheme();
  return (
    <Stack gap={4}>
      <Text size="small" tone="secondary">
        {label}
      </Text>
      <div
        style={{
          padding: "8px 10px",
          border: `1px solid ${theme.stroke.secondary}`,
          background: theme.bg.editor,
          color: theme.text.tertiary,
          fontSize: 12,
        }}
      >
        {placeholder}
      </div>
    </Stack>
  );
}

function PhotoBox({ label, height }: { label: string; height: number }) {
  const theme = useHostTheme();
  return (
    <div
      style={{
        height,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: theme.fill.tertiary,
        border: `1px dashed ${theme.stroke.secondary}`,
        color: theme.text.tertiary,
        fontSize: 12,
      }}
    >
      {label}
    </div>
  );
}
