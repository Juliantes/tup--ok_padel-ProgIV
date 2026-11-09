-- Mapeo español (enunciado) -> columnas en inglés (Rails/Geoapify):
-- calle -> street, numero -> housenumber, ciudad -> city, provincia -> province,
-- codigo_postal -> postcode, pais -> country

CREATE TABLE addresses (
  id BIGSERIAL PRIMARY KEY,
  street VARCHAR(255),
  housenumber VARCHAR(64),
  city VARCHAR(255),
  province VARCHAR(255),
  postcode VARCHAR(32),
  country VARCHAR(255),
  formatted TEXT NOT NULL,
  lat DECIMAL(10, 7) NOT NULL,
  lng DECIMAL(11, 7) NOT NULL,
  place_id VARCHAR NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX index_addresses_on_place_id ON addresses (place_id);

-- Índices para LIKE con comodín solo al final (PostgreSQL varchar_pattern_ops / text_pattern_ops)
CREATE INDEX index_addresses_on_city_prefix ON addresses (city varchar_pattern_ops);
CREATE INDEX index_addresses_on_street_prefix ON addresses (street varchar_pattern_ops);
CREATE INDEX index_addresses_on_formatted_prefix ON addresses (formatted text_pattern_ops);

-- Ejemplo de consulta local (sin Geoapify):
-- SELECT * FROM addresses WHERE city LIKE 'La Plat%' LIMIT 5;
