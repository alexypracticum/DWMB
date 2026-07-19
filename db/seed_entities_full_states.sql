-- =============================================================================
--  META-SYSTEM: Projection States (JSONB data) для 200 сущностей
--  Дата: 2026-07-18
-- =============================================================================

SET search_path TO meta;

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
-- movie
('p0100001-0000-0000-0000-000000000001', '{"title": "Interstellar", "year": 2014, "runtime": 169, "genre": "Sci-Fi/Drama", "rating": 8.6, "budget": 165000000, "revenue": 701000000, "mpaa_rating": "PG-13", "director": "Christopher Nolan", "production_companies": ["Paramount", "Warner Bros."]}', 'h01', true, 1),
('p0100001-0000-0000-0000-000000000002', '{"title": "The Matrix", "year": 1999, "runtime": 136, "genre": "Action/Sci-Fi", "rating": 8.7, "budget": 63000000, "revenue": 467200000, "mpaa_rating": "R", "director": "The Wachowskis", "production_companies": ["Warner Bros."]}', 'h02', true, 1),
('p0100001-0000-0000-0000-000000000003', '{"title": "The Godfather", "year": 1972, "runtime": 175, "genre": "Crime/Drama", "rating": 9.2, "budget": 6000000, "revenue": 250000000, "mpaa_rating": "R", "director": "Francis Ford Coppola", "production_companies": ["Paramount"]}', 'h03', true, 1),
('p0100001-0000-0000-0000-000000000004', '{"title": "The Dark Knight", "year": 2008, "runtime": 152, "genre": "Action/Crime", "rating": 9.0, "budget": 185000000, "revenue": 1006000000, "mpaa_rating": "PG-13", "director": "Christopher Nolan", "production_companies": ["Warner Bros."]}', 'h04', true, 1),
('p0100001-0000-0000-0000-000000000005', '{"title": "Inception", "year": 2010, "runtime": 148, "genre": "Action/Sci-Fi", "rating": 8.8, "budget": 160000000, "revenue": 839000000, "mpaa_rating": "PG-13", "director": "Christopher Nolan", "tagline": "Your mind is the scene of the crime", "production_companies": ["Warner Bros.", "Legendary"]}', 'h05', true, 1),
-- actor
('p0200001-0000-0000-0000-000000000001', '{"first_name": "Matthew", "last_name": "McConaughey", "birth_date": "1969-11-04", "birth_place": "Uvalde, Texas, USA", "nationality": "American", "height_cm": 182, "occupation": "Actor, Producer"}', 'h06', true, 1),
('p0200001-0000-0000-0000-000000000002', '{"first_name": "Keanu", "last_name": "Reeves", "birth_date": "1964-09-02", "birth_place": "Beirut, Lebanon", "nationality": "Canadian", "height_cm": 186, "occupation": "Actor, Producer"}', 'h07', true, 1),
('p0200001-0000-0000-0000-000000000003', '{"first_name": "Marlon", "last_name": "Brando", "birth_date": "1924-04-03", "birth_place": "Omaha, Nebraska, USA", "death_date": "2004-07-01", "nationality": "American", "height_cm": 175, "occupation": "Actor"}', 'h08', true, 1),
('p0200001-0000-0000-0000-000000000004', '{"first_name": "Christian", "last_name": "Bale", "birth_date": "1974-01-30", "birth_place": "Haverfordwest, Wales", "nationality": "British", "height_cm": 183, "occupation": "Actor"}', 'h09', true, 1),
('p0200001-0000-0000-0000-000000000005', '{"first_name": "Leonardo", "last_name": "DiCaprio", "birth_date": "1974-11-11", "birth_place": "Los Angeles, California", "nationality": "American", "height_cm": 183, "occupation": "Actor, Producer"}', 'h10', true, 1),
-- director
('p0300001-0000-0000-0000-000000000001', '{"first_name": "Christopher", "last_name": "Nolan", "birth_date": "1970-07-30", "birth_place": "London, UK", "nationality": "British-American", "notable_works": ["Inception", "Interstellar", "The Dark Knight"]}', 'h11', true, 1),
('p0300001-0000-0000-0000-000000000002', '{"first_name": "Martin", "last_name": "Scorsese", "birth_date": "1942-11-17", "birth_place": "Queens, New York", "nationality": "American", "notable_works": ["Goodfellas", "The Irishman", "Taxi Driver"]}', 'h12', true, 1),
('p0300001-0000-0000-0000-000000000003', '{"first_name": "Steven", "last_name": "Spielberg", "birth_date": "1946-12-18", "birth_place": "Cincinnati, Ohio", "nationality": "American", "notable_works": ["Jurassic Park", "Schindler''s List", "E.T."]}', 'h13', true, 1),
('p0300001-0000-0000-0000-000000000004', '{"first_name": "Quentin", "last_name": "Tarantino", "birth_date": "1963-03-27", "birth_place": "Knoxville, Tennessee", "nationality": "American", "notable_works": ["Pulp Fiction", "Kill Bill", "Inglourious Basterds"]}', 'h14', true, 1),
('p0300001-0000-0000-0000-000000000005', '{"first_name": "David", "last_name": "Lynch", "birth_date": "1946-01-20", "birth_place": "Missoula, Montana", "nationality": "American", "notable_works": ["Mulholland Drive", "Blue Velvet", "Twin Peaks"]}', 'h15', true, 1),
-- song
('p0400001-0000-0000-0000-000000000001', '{"title": "Bohemian Rhapsody", "artist": "Queen", "album": "A Night at the Opera", "year": 1975, "duration_sec": 355, "genre": "Rock", "key": "Bb major"}', 'h16', true, 1),
('p0400001-0000-0000-0000-000000000002', '{"title": "Imagine", "artist": "John Lennon", "year": 1971, "duration_sec": 187, "genre": "Pop/Rock", "key": "C major"}', 'h17', true, 1),
('p0400001-0000-0000-0000-000000000003', '{"title": "Hotel California", "artist": "Eagles", "album": "Hotel California", "year": 1977, "duration_sec": 391, "genre": "Rock", "key": "B minor"}', 'h18', true, 1),
('p0400001-0000-0000-0000-000000000004', '{"title": "Stairway to Heaven", "artist": "Led Zeppelin", "album": "Led Zeppelin IV", "year": 1971, "duration_sec": 482, "genre": "Rock", "key": "A minor"}', 'h19', true, 1),
('p0400001-0000-0000-0000-000000000005', '{"title": "Yesterday", "artist": "The Beatles", "album": "Help!", "year": 1965, "duration_sec": 125, "genre": "Pop", "key": "F major"}', 'h20', true, 1),
-- musician
('p0500001-0000-0000-0000-000000000001', '{"first_name": "Freddie", "last_name": "Mercury", "birth_date": "1946-09-05", "birth_place": "Zanzibar", "death_date": "1991-11-24", "occupation": "Singer, songwriter", "band": "Queen"}', 'h21', true, 1),
('p0500001-0000-0000-0000-000000000002', '{"first_name": "John", "last_name": "Lennon", "birth_date": "1940-10-09", "birth_place": "Liverpool, UK", "death_date": "1980-12-08", "occupation": "Singer, songwriter", "band": "The Beatles"}', 'h22', true, 1),
('p0500001-0000-0000-0000-000000000003', '{"first_name": "Eric", "last_name": "Clapton", "birth_date": "1945-05-30", "birth_place": "Surrey, UK", "occupation": "Guitarist, singer", "instruments": ["Guitar", "Vocals"]}', 'h23', true, 1),
('p0500001-0000-0000-0000-000000000004', '{"first_name": "Jimmy", "last_name": "Page", "birth_date": "1944-01-09", "birth_place": "Heston, UK", "occupation": "Guitarist, composer", "band": "Led Zeppelin", "instruments": ["Guitar"]}', 'h24', true, 1),
('p0500001-0000-0000-0000-000000000005', '{"first_name": "Robert", "last_name": "Plant", "birth_date": "1948-08-20", "birth_place": "West Bromwich, UK", "occupation": "Singer, songwriter", "band": "Led Zeppelin"}', 'h25', true, 1),
-- album
('p0600001-0000-0000-0000-000000000001', '{"title": "A Night at the Opera", "artist": "Queen", "year": 1975, "genre": "Rock", "tracks": 12, "label": "EMI", "total_length_sec": 2627}', 'h26', true, 1),
('p0600001-0000-0000-0000-000000000002', '{"title": "Abbey Road", "artist": "The Beatles", "year": 1969, "genre": "Rock", "tracks": 17, "label": "Apple Records", "total_length_sec": 2767}', 'h27', true, 1),
('p0600001-0000-0000-0000-000000000003', '{"title": "The Dark Side of the Moon", "artist": "Pink Floyd", "year": 1973, "genre": "Progressive Rock", "tracks": 10, "label": "Harvest", "total_length_sec": 2580}', 'h28', true, 1),
('p0600001-0000-0000-0000-000000000004', '{"title": "Thriller", "artist": "Michael Jackson", "year": 1982, "genre": "Pop", "tracks": 9, "label": "Epic", "total_length_sec": 2523}', 'h29', true, 1),
('p0600001-0000-0000-0000-000000000005', '{"title": "Back in Black", "artist": "AC/DC", "year": 1980, "genre": "Hard Rock", "tracks": 10, "label": "Atlantic", "total_length_sec": 2606}', 'h30', true, 1),
-- book
('p0700001-0000-0000-0000-000000000001', '{"title": "War and Peace", "author": "Leo Tolstoy", "year": 1869, "pages": 1225, "publisher": "The Russian Messenger", "genre": "Historical Fiction", "language": "Russian"}', 'h31', true, 1),
('p0700001-0000-0000-0000-000000000002', '{"title": "1984", "author": "George Orwell", "year": 1949, "pages": 328, "publisher": "Secker & Warburg", "genre": "Dystopian Fiction", "isbn": "978-0-452-28423-4"}', 'h32', true, 1),
('p0700001-0000-0000-0000-000000000003', '{"title": "The Master and Margarita", "author": "Mikhail Bulgakov", "year": 1967, "pages": 384, "publisher": "YMCA-Press", "genre": "Magical Realism"}', 'h33', true, 1),
('p0700001-0000-0000-0000-000000000004', '{"title": "Crime and Punishment", "author": "Fyodor Dostoevsky", "year": 1866, "pages": 551, "publisher": "The Russian Messenger", "genre": "Psychological Fiction"}', 'h34', true, 1),
('p0700001-0000-0000-0000-000000000005', '{"title": "Harry Potter and the Philosopher''s Stone", "author": "J.K. Rowling", "year": 1997, "pages": 223, "publisher": "Bloomsbury", "genre": "Fantasy", "isbn": "978-0-7475-3269-9"}', 'h35', true, 1),
-- writer
('p0800001-0000-0000-0000-000000000001', '{"first_name": "Leo", "last_name": "Tolstoy", "birth_date": "1828-09-09", "birth_place": "Yasnaya Polyana, Russia", "death_date": "1910-11-20", "nationality": "Russian", "notable_works": ["War and Peace", "Anna Karenina"]}', 'h36', true, 1),
('p0800001-0000-0000-0000-000000000002', '{"first_name": "George", "last_name": "Orwell", "birth_date": "1903-06-25", "birth_place": "Motihari, India", "death_date": "1950-01-21", "nationality": "British", "notable_works": ["1984", "Animal Farm"]}', 'h37', true, 1),
('p0800001-0000-0000-0000-000000000003', '{"first_name": "Mikhail", "last_name": "Bulgakov", "birth_date": "1891-05-15", "birth_place": "Kiev, Ukraine", "death_date": "1940-03-10", "nationality": "Russian", "notable_works": ["The Master and Margarita", "The White Guard"]}', 'h38', true, 1),
('p0800001-0000-0000-0000-000000000004', '{"first_name": "Fyodor", "last_name": "Dostoevsky", "birth_date": "1821-11-11", "birth_place": "Moscow, Russia", "death_date": "1881-01-28", "nationality": "Russian", "notable_works": ["Crime and Punishment", "The Brothers Karamazov"]}', 'h39', true, 1),
('p0800001-0000-0000-0000-000000000005', '{"first_name": "J.K.", "last_name": "Rowling", "birth_date": "1965-07-31", "birth_place": "Yate, UK", "nationality": "British", "notable_works": ["Harry Potter series", "Fantastic Beasts"]}', 'h40', true, 1),
-- place
('p0900001-0000-0000-0000-000000000001', '{"city": "Moscow", "country": "Russia", "population": 12600000, "latitude": 55.7558, "longitude": 37.6173, "timezone": "UTC+3", "founded": 1147}', 'h41', true, 1),
('p0900001-0000-0000-0000-000000000002', '{"city": "New York", "country": "USA", "population": 8300000, "latitude": 40.7128, "longitude": -74.0060, "timezone": "UTC-5", "founded": 1624}', 'h42', true, 1),
('p0900001-0000-0000-0000-000000000003', '{"city": "London", "country": "UK", "population": 8980000, "latitude": 51.5074, "longitude": -0.1278, "timezone": "UTC+0", "founded": 43}', 'h43', true, 1),
('p0900001-0000-0000-0000-000000000004', '{"city": "Tokyo", "country": "Japan", "population": 13960000, "latitude": 35.6762, "longitude": 139.6503, "timezone": "UTC+9", "founded": 1457}', 'h44', true, 1),
('p0900001-0000-0000-0000-000000000005', '{"city": "Paris", "country": "France", "population": 2161000, "latitude": 48.8566, "longitude": 2.3522, "timezone": "UTC+1", "founded": -250}', 'h45', true, 1),
-- chemical_element
('p1000001-0000-0000-0000-000000000001', '{"element": "Hydrogen", "symbol": "H", "atomic_number": 1, "atomic_mass": 1.008, "electron_configuration": "1s1", "melting_point": -259.16, "boiling_point": -252.87, "category": "Nonmetal"}', 'h46', true, 1),
('p1000001-0000-0000-0000-000000000002', '{"element": "Oxygen", "symbol": "O", "atomic_number": 8, "atomic_mass": 15.999, "electron_configuration": "[He] 2s2 2p4", "melting_point": -218.79, "boiling_point": -182.96, "category": "Nonmetal"}', 'h47', true, 1),
('p1000001-0000-0000-0000-000000000003', '{"element": "Carbon", "symbol": "C", "atomic_number": 6, "atomic_mass": 12.011, "electron_configuration": "[He] 2s2 2p2", "melting_point": 3550, "boiling_point": 4027, "category": "Nonmetal"}', 'h48', true, 1),
('p1000001-0000-0000-0000-000000000004', '{"element": "Iron", "symbol": "Fe", "atomic_number": 26, "atomic_mass": 55.845, "electron_configuration": "[Ar] 3d6 4s2", "melting_point": 1538, "boiling_point": 2862, "category": "Transition Metal"}', 'h49', true, 1),
('p1000001-0000-0000-0000-000000000005', '{"element": "Gold", "symbol": "Au", "atomic_number": 79, "atomic_mass": 196.967, "electron_configuration": "[Xe] 4f14 5d10 6s1", "melting_point": 1064.18, "boiling_point": 2856, "category": "Transition Metal"}', 'h50', true, 1),
-- animal
('p1100001-0000-0000-0000-000000000001', '{"common_name": "Wolf", "scientific_name": "Canis lupus", "class": "Mammalia", "order": "Carnivora", "family": "Canidae", "habitat": "Forests, tundra", "diet": "Carnivore", "lifespan": "6-8 years"}', 'h51', true, 1),
('p1100001-0000-0000-0000-000000000002', '{"common_name": "Golden Eagle", "scientific_name": "Aquila chrysaetos", "class": "Aves", "order": "Accipitriformes", "family": "Accipitridae", "habitat": "Mountains, open areas", "wingspan_cm": 220}', 'h52', true, 1),
('p1100001-0000-0000-0000-000000000003', '{"common_name": "Bottlenose Dolphin", "scientific_name": "Tursiops truncatus", "class": "Mammalia", "order": "Artiodactyla", "family": "Delphinidae", "habitat": "Oceans worldwide", "lifespan": "40-50 years"}', 'h53', true, 1),
('p1100001-0000-0000-0000-000000000004', '{"common_name": "Lion", "scientific_name": "Panthera leo", "class": "Mammalia", "order": "Carnivora", "family": "Felidae", "habitat": "Savannas, grasslands", "diet": "Carnivore", "lifespan": "10-14 years"}', 'h54', true, 1),
('p1100001-0000-0000-0000-000000000005', '{"common_name": "Brown Bear", "scientific_name": "Ursus arctos", "class": "Mammalia", "order": "Carnivora", "family": "Ursidae", "habitat": "Forests, mountains", "diet": "Omnivore", "lifespan": "25-30 years"}', 'h55', true, 1),
-- plant
('p1200001-0000-0000-0000-000000000001', '{"common_name": "Oak", "scientific_name": "Quercus", "family": "Fagaceae", "type": "Deciduous tree", "height_m": "20-40", "lifespan": "200-1000 years"}', 'h56', true, 1),
('p1200001-0000-0000-0000-000000000002', '{"common_name": "Birch", "scientific_name": "Betula", "family": "Betulaceae", "type": "Deciduous tree", "height_m": "15-30", "lifespan": "40-60 years"}', 'h57', true, 1),
('p1200001-0000-0000-0000-000000000003', '{"common_name": "Cactus", "scientific_name": "Cactaceae", "family": "Cactaceae", "type": "Succulent", "habitat": "Arid regions"}', 'h58', true, 1),
('p1200001-0000-0000-0000-000000000004', '{"common_name": "Wheat", "scientific_name": "Triticum", "family": "Poaceae", "type": "Cereal crop", "origin": "Fertile Crescent", "uses": ["Food", "Animal feed"]}', 'h59', true, 1),
('p1200001-0000-0000-0000-000000000005', '{"common_name": "Rice", "scientific_name": "Oryza sativa", "family": "Poaceae", "type": "Cereal crop", "origin": "East Asia", "uses": ["Food"]}', 'h60', true, 1),
-- concept
('p1300001-0000-0000-0000-000000000001', '{"name": "Democracy", "description": "A system of government by the whole population", "origins": "Ancient Greece", "variants": ["Direct", "Representative"]}', 'h61', true, 1),
('p1300001-0000-0000-0000-000000000002', '{"name": "Cyberpunk", "description": "A subgenre of science fiction set in a lawless digital world", "origins": "1980s", "key_works": ["Neuromancer", "Blade Runner"]}', 'h62', true, 1),
('p1300001-0000-0000-0000-000000000003', '{"name": "Artificial Intelligence", "description": "Intelligence demonstrated by machines", "subfields": ["Machine Learning", "NLP", "Computer Vision"]}', 'h63', true, 1),
('p1300001-0000-0000-0000-000000000004', '{"name": "Freedom", "description": "Power of self-determination not subject to outside constraint", "philosophers": ["John Stuart Mill", "Isaiah Berlin"]}', 'h64', true, 1),
('p1300001-0000-0000-0000-000000000005', '{"name": "Justice", "description": "Just behavior or treatment", "types": ["Distributive", "Procedural", "Retributive"]}', 'h65', true, 1),
-- genre
('p1400001-0000-0000-0000-000000000001', '{"name": "Science Fiction", "description": "Speculative fiction dealing with futuristic concepts", "subgenres": ["Cyberpunk", "Space Opera", "Dystopian"], "media": ["Film", "Literature", "TV"]}', 'h66', true, 1),
('p1400001-0000-0000-0000-000000000002', '{"name": "Classical Music", "description": "Art music rooted in Western tradition", "periods": ["Baroque", "Classical", "Romantic", "Modern"]}', 'h67', true, 1),
('p1400001-0000-0000-0000-000000000003', '{"name": "Rock", "description": "Popular music genre", "subgenres": ["Hard Rock", "Progressive Rock", "Punk Rock"], "origins": "1950s USA"}', 'h68', true, 1),
('p1400001-0000-0000-0000-000000000004', '{"name": "Jazz", "description": "Music genre with roots in African-American communities", "subgenres": ["Bebop", "Swing", "Fusion"], "origins": "Late 19th century New Orleans"}', 'h69', true, 1),
('p1400001-0000-0000-0000-000000000005', '{"name": "Pop", "description": "Popular music genre", "characteristics": ["Catchy melodies", "Verse-chorus structure"], "origins": "1950s"}', 'h70', true, 1),
-- phenomenon
('p1500001-0000-0000-0000-000000000001', '{"name": "Gravity", "description": "Fundamental interaction between masses", "formula": "F = G * m1 * m2 / r^2", "discoverer": "Newton (1687)"}', 'h71', true, 1),
('p1500001-0000-0000-0000-000000000002', '{"name": "Photosynthesis", "description": "Process by which plants convert light to energy", "formula": "6CO2 + 6H2O → C6H12O6 + 6O2", "location": "Chloroplasts"}', 'h72', true, 1),
('p1500001-0000-0000-0000-000000000003', '{"name": "Magnetic Field", "description": "Vector field describing magnetic influence", "units": "Tesla (T)", "sources": ["Electric currents", "Magnets"]}', 'h73', true, 1),
('p1500001-0000-0000-0000-000000000004', '{"name": "Evolution", "description": "Change in heritable characteristics over generations", "mechanisms": ["Natural Selection", "Genetic Drift", "Mutation"]}', 'h74', true, 1),
('p1500001-0000-0000-0000-000000000005', '{"name": "Quantum Superposition", "description": "Quantum state of being in multiple states simultaneously", "principle": "Schrödinger''s cat", "discoverer": "Schrödinger (1935)"}', 'h75', true, 1),
-- period
('p1600001-0000-0000-0000-000000000001', '{"name": "Middle Ages", "description": "Period of European history", "start_year": 500, "end_year": 1500, "key_events": ["Fall of Rome", "Crusades", "Black Death"]}', 'h76', true, 1),
('p1600001-0000-0000-0000-000000000002', '{"name": "Renaissance", "description": "Cultural rebirth in Europe", "start_year": 1300, "end_year": 1600, "key_figures": ["Leonardo da Vinci", "Michelangelo"]}', 'h77', true, 1),
('p1600001-0000-0000-0000-000000000003', '{"name": "Enlightenment", "description": "Intellectual movement of the 18th century", "start_year": 1685, "end_year": 1815, "key_figures": ["Voltaire", "Kant", "Rousseau"]}', 'h78', true, 1),
('p1600001-0000-0000-0000-000000000004', '{"name": "Industrial Revolution", "description": "Transition to new manufacturing processes", "start_year": 1760, "end_year": 1840, "key_inventions": ["Steam Engine", "Spinning Jenny"]}', 'h79', true, 1),
('p1600001-0000-0000-0000-000000000005', '{"name": "Digital Era", "description": "Age of information technology", "start_year": 1970, "key_developments": ["Internet", "Personal Computers", "Smartphones"]}', 'h80', true, 1),
-- digital_file
('p1700001-0000-0000-0000-000000000001', '{"filename": "main.py", "format": "Python", "size_bytes": 1200, "encoding": "UTF-8", "description": "Main application entry point"}', 'h81', true, 1),
('p1700001-0000-0000-0000-000000000002', '{"filename": "init.sql", "format": "SQL", "size_bytes": 45000, "encoding": "UTF-8", "description": "Database initialization script"}', 'h82', true, 1),
('p1700001-0000-0000-0000-000000000003', '{"filename": "README.md", "format": "Markdown", "size_bytes": 2500, "encoding": "UTF-8", "description": "Project documentation"}', 'h83', true, 1),
('p1700001-0000-0000-0000-000000000004', '{"filename": "config.json", "format": "JSON", "size_bytes": 800, "encoding": "UTF-8", "description": "Application configuration"}', 'h84', true, 1),
('p1700001-0000-0000-0000-000000000005', '{"filename": "Dockerfile", "format": "Docker", "size_bytes": 500, "encoding": "UTF-8", "description": "Docker container build instructions"}', 'h85', true, 1),
-- movement
('p1800001-0000-0000-0000-000000000001', '{"name": "Modernism", "description": "Western art movement", "period": "Late 19th - mid 20th century", "key_artists": ["Pablo Picasso", "T.S. Eliot"], "characteristics": ["Experimental", "Fragmented"]}', 'h86', true, 1),
('p1800001-0000-0000-0000-000000000002', '{"name": "Postmodernism", "description": "Movement reacting against modernism", "period": "Mid 20th century onwards", "key_artists": ["Andy Warhol", "Jean Baudrillard"], "characteristics": ["Irony", "Pastiche"]}', 'h87', true, 1),
('p1800001-0000-0000-0000-000000000003', '{"name": "Avant-garde", "description": "Experimental and innovative art", "period": "Early 20th century", "key_movements": ["Futurism", "Dadaism", "Surrealism"]}', 'h88', true, 1),
('p1800001-0000-0000-0000-000000000004', '{"name": "Romanticism", "description": "Artistic and intellectual movement", "period": "Late 18th - mid 19th century", "key_artists": ["Beethoven", "Turner"], "characteristics": ["Emotion", "Individualism"]}', 'h89', true, 1),
('p1800001-0000-0000-0000-000000000005', '{"name": "Realism", "description": "Art movement depicting reality", "period": "Mid 19th century", "key_artists": ["Courbet", "Tolstoy"], "characteristics": ["Everyday subjects", "Truthful representation"]}', 'h90', true, 1),
-- classifier
('p1900001-0000-0000-0000-000000000001', '{"name": "Dewey Decimal Classification", "description": "Library classification system", "creator": "Melvil Dewey", "year": 1876, "categories": 10}', 'h91', true, 1),
('p1900001-0000-0000-0000-000000000002', '{"name": "Periodic Table", "description": "Tabular arrangement of chemical elements", "creator": "Dmitri Mendeleev", "year": 1869, "elements": 118}', 'h92', true, 1),
('p1900001-0000-0000-0000-000000000003', '{"name": "ISO 3166", "description": "Codes for representation of countries", "organization": "ISO", "year": 1974, "parts": 3}', 'h93', true, 1),
('p1900001-0000-0000-0000-000000000004', '{"name": "RFC 2119", "description": "Key words for use in RFCs", "organization": "IETF", "year": 1997, "keywords": ["MUST", "SHOULD", "MAY"]}', 'h94', true, 1),
('p1900001-0000-0000-0000-000000000005', '{"name": "BCP 47", "description": "Language tag identification", "organization": "IETF", "tags": ["en", "ru", "zh", "ja"]}', 'h95', true, 1),
-- physical_item
('p2000001-0000-0000-0000-000000000001', '{"name": "Desk", "material": "Wood/Metal", "dimensions": "120x60x75 cm", "purpose": "Work surface"}', 'h96', true, 1),
('p2000001-0000-0000-0000-000000000002', '{"name": "Chair", "material": "Wood/Fabric", "dimensions": "50x50x85 cm", "purpose": "Seating"}', 'h97', true, 1),
('p2000001-0000-0000-0000-000000000003', '{"name": "Computer", "type": "Desktop/Laptop", "components": ["CPU", "RAM", "Storage", "GPU"], "purpose": "Computing"}', 'h98', true, 1),
('p2000001-0000-0000-0000-000000000004', '{"name": "Notebook", "pages": 100, "size": "A5", "cover": "Hardcover", "purpose": "Writing"}', 'h99', true, 1),
('p2000001-0000-0000-0000-000000000005', '{"name": "Pen", "type": "Ballpoint", "color": "Blue", "purpose": "Writing"}', 'h100', true, 1),
-- photo
('p2100001-0000-0000-0000-000000000001', '{"title": "Portrait", "type": "Portrait photography", "subject": "Person", "technique": "Studio lighting"}', 'h101', true, 1),
('p2100001-0000-0000-0000-000000000002', '{"title": "Landscape", "type": "Landscape photography", "subject": "Nature", "technique": "Wide angle"}', 'h102', true, 1),
('p2100001-0000-0000-0000-000000000003', '{"title": "Macro Shot", "type": "Macro photography", "subject": "Close-up", "technique": "Macro lens"}', 'h103', true, 1),
('p2100001-0000-0000-0000-000000000004', '{"title": "Night City", "type": "Night photography", "subject": "Urban", "technique": "Long exposure"}', 'h104', true, 1),
('p2100001-0000-0000-0000-000000000005', '{"title": "Mountains", "type": "Landscape photography", "subject": "Mountains", "technique": "HDR"}', 'h105', true, 1),
-- article
('p2200001-0000-0000-0000-000000000001', '{"title": "Scientific Paper", "type": "Research paper", "peer_reviewed": true, "format": "Academic"}', 'h106', true, 1),
('p2200001-0000-0000-0000-000000000002', '{"title": "News Article", "type": "Journalism", "timeliness": "Current events", "format": "News"}', 'h107', true, 1),
('p2200001-0000-0000-0000-000000000003', '{"title": "Review", "type": "Critique", "subject": "Creative work", "format": "Critical analysis"}', 'h108', true, 1),
('p2200001-0000-0000-0000-000000000004', '{"title": "Essay", "type": "Prose", "purpose": "Argumentation", "format": "Literary"}', 'h109', true, 1),
('p2200001-0000-0000-0000-000000000005', '{"title": "Interview", "type": "Q&A", "format": "Transcript", "purpose": "Information gathering"}', 'h110', true, 1),
-- human
('p2300001-0000-0000-0000-000000000001', '{"first_name": "Albert", "last_name": "Einstein", "birth_date": "1879-03-14", "birth_place": "Ulm, Germany", "death_date": "1955-04-18", "nationality": "German-American", "occupation": "Physicist", "notable_works": ["Theory of Relativity", "E=mc²"]}', 'h111', true, 1),
('p2300001-0000-0000-0000-000000000002', '{"first_name": "Marie", "last_name": "Curie", "birth_date": "1867-11-07", "birth_place": "Warsaw, Poland", "death_date": "1934-07-04", "nationality": "Polish-French", "occupation": "Physicist, Chemist", "notable_works": ["Discovery of Radium", "Polonium"]}', 'h112', true, 1),
('p2300001-0000-0000-0000-000000000003', '{"first_name": "Nikola", "last_name": "Tesla", "birth_date": "1856-07-10", "birth_place": "Smiljan, Croatia", "death_date": "1943-01-07", "nationality": "Serbian-American", "occupation": "Inventor, Engineer", "notable_works": ["AC Motor", "Tesla Coil"]}', 'h113', true, 1),
('p2300001-0000-0000-0000-000000000004', '{"first_name": "Leonardo", "last_name": "da Vinci", "birth_date": "1452-04-15", "birth_place": "Anchiano, Italy", "death_date": "1519-05-02", "nationality": "Italian", "occupation": "Polymath", "notable_works": ["Mona Lisa", "Vitruvian Man"]}', 'h114', true, 1),
('p2300001-0000-0000-0000-000000000005', '{"first_name": "Charles", "last_name": "Darwin", "birth_date": "1809-02-12", "birth_place": "Shrewsbury, UK", "death_date": "1882-04-19", "nationality": "British", "occupation": "Naturalist", "notable_works": ["On the Origin of Species"]}', 'h115', true, 1),
-- artist
('p2400001-0000-0000-0000-000000000001', '{"first_name": "Pablo", "last_name": "Picasso", "birth_date": "1881-10-25", "birth_place": "Malaga, Spain", "death_date": "1973-04-08", "nationality": "Spanish", "movement": "Cubism", "notable_works": ["Guernica", "Les Demoiselles d''Avignon"]}', 'h116', true, 1),
('p2400001-0000-0000-0000-000000000002', '{"first_name": "Vincent", "last_name": "van Gogh", "birth_date": "1853-03-30", "birth_place": "Groot-Zundert, Netherlands", "death_date": "1890-07-29", "nationality": "Dutch", "movement": "Post-Impressionism", "notable_works": ["Starry Night", "Sunflowers"]}', 'h117', true, 1),
('p2400001-0000-0000-0000-000000000003', '{"first_name": "Claude", "last_name": "Monet", "birth_date": "1840-11-14", "birth_place": "Paris, France", "death_date": "1926-12-05", "nationality": "French", "movement": "Impressionism", "notable_works": ["Water Lilies", "Impression, Sunrise"]}', 'h118', true, 1),
('p2400001-0000-0000-0000-000000000004', '{"first_name": "Salvador", "last_name": "Dali", "birth_date": "1904-05-11", "birth_place": "Figueres, Spain", "death_date": "1989-01-23", "nationality": "Spanish", "movement": "Surrealism", "notable_works": ["The Persistence of Memory"]}', 'h119', true, 1),
('p2400001-0000-0000-0000-000000000005', '{"first_name": "Kazimir", "last_name": "Malevich", "birth_date": "1879-02-23", "birth_place": "Kiev, Ukraine", "death_date": "1935-05-15", "nationality": "Russian", "movement": "Suprematism", "notable_works": ["Black Square"]}', 'h120', true, 1),
-- scientist
('p2500001-0000-0000-0000-000000000001', '{"first_name": "Isaac", "last_name": "Newton", "birth_date": "1643-01-04", "birth_place": "Woolsthorpe, UK", "death_date": "1727-03-31", "nationality": "British", "field": "Physics, Mathematics", "notable_works": ["Principia Mathematica", "Laws of Motion"]}', 'h121', true, 1),
('p2500001-0000-0000-0000-000000000002', '{"first_name": "Richard", "last_name": "Feynman", "birth_date": "1918-05-11", "birth_place": "Queens, New York", "death_date": "1988-02-15", "nationality": "American", "field": "Quantum Physics", "notable_works": ["Feynman Diagrams", "QED"]}', 'h122', true, 1),
('p2500001-0000-0000-0000-000000000003', '{"first_name": "Stephen", "last_name": "Hawking", "birth_date": "1942-01-08", "birth_place": "Oxford, UK", "death_date": "2018-03-14", "nationality": "British", "field": "Theoretical Physics", "notable_works": ["A Brief History of Time"]}', 'h123', true, 1),
('p2500001-0000-0000-0000-000000000004', '{"first_name": "Niels", "last_name": "Bohr", "birth_date": "1885-10-07", "birth_place": "Copenhagen, Denmark", "death_date": "1962-11-18", "nationality": "Danish", "field": "Atomic Physics", "notable_works": ["Bohr Model of the Atom"]}', 'h124', true, 1),
('p2500001-0000-0000-0000-000000000005', '{"first_name": "Max", "last_name": "Planck", "birth_date": "1858-04-23", "birth_place": "Kiel, Germany", "death_date": "1947-10-04", "nationality": "German", "field": "Quantum Physics", "notable_works": ["Quantum Theory", "Planck''s Constant"]}', 'h125', true, 1),
-- organization
('p2600001-0000-0000-0000-000000000001', '{"name": "Google", "founded": 1998, "founders": ["Larry Page", "Sergey Brin"], "headquarters": "Mountain View, California", "industry": "Technology", "employees": 180000}', 'h126', true, 1),
('p2600001-0000-0000-0000-000000000002', '{"name": "Apple", "founded": 1976, "founders": ["Steve Jobs", "Steve Wozniak", "Ronald Wayne"], "headquarters": "Cupertino, California", "industry": "Technology", "employees": 164000}', 'h127', true, 1),
('p2600001-0000-0000-0000-000000000003', '{"name": "Wikipedia", "founded": 2001, "founders": ["Jimmy Wales", "Larry Sanger"], "headquarters": "San Francisco, California", "type": "Online encyclopedia", "languages": 300}', 'h128', true, 1),
('p2600001-0000-0000-0000-000000000004', '{"name": "United Nations", "founded": 1945, "founders": ["51 member states"], "headquarters": "New York", "type": "International organization", "members": 193}', 'h129', true, 1),
('p2600001-0000-0000-0000-000000000005', '{"name": "Microsoft", "founded": 1975, "founders": ["Bill Gates", "Paul Allen"], "headquarters": "Redmond, Washington", "industry": "Technology", "employees": 221000}', 'h130', true, 1),
-- event
('p2700001-0000-0000-0000-000000000001', '{"name": "Olympics 2024", "type": "Sports", "location": "Paris, France", "start_date": "2024-07-26", "end_date": "2024-08-11", "participants": 10500}', 'h131', true, 1),
('p2700001-0000-0000-0000-000000000002', '{"name": "Cannes Film Festival", "type": "Film festival", "location": "Cannes, France", "founded": 1946, "category": "Palme d''Or"}', 'h132', true, 1),
('p2700001-0000-0000-0000-000000000003', '{"name": "CES 2025", "type": "Technology exhibition", "location": "Las Vegas, USA", "founded": 1967, "attendees": 130000}', 'h133', true, 1),
('p2700001-0000-0000-0000-000000000004', '{"name": "WWDC", "type": "Developer conference", "organizer": "Apple", "founded": 1987, "format": "Hybrid"}', 'h134', true, 1),
('p2700001-0000-0000-0000-000000000005', '{"name": "World War II", "type": "Global conflict", "start_date": "1939-09-01", "end_date": "1945-09-02", "casualties": 70000000, "belligerents": ["Allies", "Axis"]}', 'h135', true, 1),
-- award
('p2800001-0000-0000-0000-000000000001', '{"name": "Academy Award (Oscar)", "category": "Film", "founded": 1929, "organization": "Academy of Motion Picture Arts and Sciences", "categories": 24}', 'h136', true, 1),
('p2800001-0000-0000-0000-000000000002', '{"name": "Grammy Award", "category": "Music", "founded": 1959, "organization": "Recording Academy", "categories": 91}', 'h137', true, 1),
('p2800001-0000-0000-0000-000000000003', '{"name": "Nobel Prize", "category": "Science, Literature, Peace", "founded": 1901, "founder": "Alfred Nobel", "categories": 6}', 'h138', true, 1),
('p2800001-0000-0000-0000-000000000004', '{"name": "Pulitzer Prize", "category": "Journalism, Literature", "founded": 1917", "founder": "Joseph Pulitzer", "categories": 21}', 'h139', true, 1),
('p2800001-0000-0000-0000-000000000005', '{"name": "Tony Award", "category": "Theater", "founded": 1949, "organization": "American Theatre Wing", "categories": 26}', 'h140', true, 1),
-- collection
('p2900001-0000-0000-0000-000000000001', '{"name": "State Hermitage Museum", "location": "Saint Petersburg, Russia", "founded": 1764, "collection_size": 3000000, "artifacts": ["Paintings", "Sculptures", "Archaeological"]}', 'h141', true, 1),
('p2900001-0000-0000-0000-000000000002', '{"name": "Louvre Museum", "location": "Paris, France", "founded": 1793, "collection_size": 380000, "artifacts": ["Mona Lisa", "Venus de Milo"]}', 'h142', true, 1),
('p2900001-0000-0000-0000-000000000003', '{"name": "Metropolitan Museum of Art", "location": "New York, USA", "founded": 1870, "collection_size": 2000000, "artifacts": ["Paintings", "Arms", "Costumes"]}', 'h143', true, 1),
('p2900001-0000-0000-0000-000000000004', '{"name": "Tretyakov Gallery", "location": "Moscow, Russia", "founded": 1856, "collection_size": 200000, "artifacts": ["Russian art"]}', 'h144', true, 1),
('p2900001-0000-0000-0000-000000000005', '{"name": "British Museum", "location": "London, UK", "founded": 1753, "collection_size": 8000000, "artifacts": ["Rosetta Stone", "Egyptian mummies"]}', 'h145', true, 1),
-- tag
('p3000001-0000-0000-0000-000000000001', '{"name": "sci-fi", "description": "Science fiction related", "category": "Genre", "usage_count": 150}', 'h146', true, 1),
('p3000001-0000-0000-0000-000000000002', '{"name": "classic", "description": "Classic/canonical works", "category": "Quality", "usage_count": 200}', 'h147', true, 1),
('p3000001-0000-0000-0000-000000000003', '{"name": "bestseller", "description": "Best-selling works", "category": "Sales", "usage_count": 80}', 'h148', true, 1),
('p3000001-0000-0000-0000-000000000004', '{"name": "award-winning", "description": "Award-winning works", "category": "Recognition", "usage_count": 120}', 'h149', true, 1),
('p3000001-0000-0000-0000-000000000005', '{"name": "cult", "description": "Cult classic works", "category": "Cultural impact", "usage_count": 60}', 'h150', true, 1),
-- language_entity
('p3100001-0000-0000-0000-000000000001', '{"name": "Python", "type": "Programming language", "paradigms": ["Object-oriented", "Functional", "Imperative"], "year": 1991, "creator": "Guido van Rossum"}', 'h151', true, 1),
('p3100001-0000-0000-0000-000000000002', '{"name": "JavaScript", "type": "Programming language", "paradigms": ["Event-driven", "Functional", "Imperative"], "year": 1995, "creator": "Brendan Eich"}', 'h152', true, 1),
('p3100001-0000-0000-0000-000000000003', '{"name": "SQL", "type": "Query language", "paradigms": ["Declarative"], "year": 1974, "creator": "Donald Chamberlin"}', 'h153', true, 1),
('p3100001-0000-0000-0000-000000000004', '{"name": "HTML", "type": "Markup language", "year": 1993, "creator": "Tim Berners-Lee", "purpose": "Web content structure"}', 'h154', true, 1),
('p3100001-0000-0000-0000-000000000005', '{"name": "CSS", "type": "Style language", "year": 1996, "creator": "Håkon Wium Lie", "purpose": "Web content presentation"}', 'h155', true, 1),
-- currency
('p3200001-0000-0000-0000-000000000001', '{"name": "US Dollar", "code": "USD", "symbol": "$", "country": "USA", "central_bank": "Federal Reserve", "subdivisions": 100}', 'h156', true, 1),
('p3200001-0000-0000-0000-000000000002', '{"name": "Euro", "code": "EUR", "symbol": "€", "country": "Eurozone", "central_bank": "ECB", "subdivisions": 100}', 'h157', true, 1),
('p3200001-0000-0000-0000-000000000003', '{"name": "Russian Ruble", "code": "RUB", "symbol": "₽", "country": "Russia", "central_bank": "Bank of Russia", "subdivisions": 100}', 'h158', true, 1),
('p3200001-0000-0000-0000-000000000004', '{"name": "Japanese Yen", "code": "JPY", "symbol": "¥", "country": "Japan", "central_bank": "Bank of Japan", "subdivisions": 100}', 'h159', true, 1),
('p3200001-0000-0000-0000-000000000005', '{"name": "Pound Sterling", "code": "GBP", "symbol": "£", "country": "UK", "central_bank": "Bank of England", "subdivisions": 100}', 'h160', true, 1),
-- unit
('p3300001-0000-0000-0000-000000000001', '{"name": "Meter", "symbol": "m", "system": "SI", "quantity": "Length", "definition": "Distance light travels in 1/299792458 second"}', 'h161', true, 1),
('p3300001-0000-0000-0000-000000000002', '{"name": "Kilogram", "symbol": "kg", "system": "SI", "quantity": "Mass", "definition": "Planck constant h = 6.62607015×10^-34 J·s"}', 'h162', true, 1),
('p3300001-0000-0000-0000-000000000003', '{"name": "Second", "symbol": "s", "system": "SI", "quantity": "Time", "definition": "9,192,631,770 periods of radiation"}', 'h163', true, 1),
('p3300001-0000-0000-0000-000000000004', '{"name": "Ampere", "symbol": "A", "system": "SI", "quantity": "Electric current", "definition": "Elementary charge e = 1.602176634×10^-19 C"}', 'h164', true, 1),
('p3300001-0000-0000-0000-000000000005', '{"name": "Kelvin", "symbol": "K", "system": "SI", "quantity": "Temperature", "definition": "1/273.16 of triple point of water"}', 'h165', true, 1),
-- formula
('p3400001-0000-0000-0000-000000000001', '{"name": "Mass-energy equivalence", "formula": "E = mc²", "discoverer": "Albert Einstein", "year": 1905, "field": "Physics"}', 'h166', true, 1),
('p3400001-0000-0000-0000-000000000002', '{"name": "Newton''s Second Law", "formula": "F = ma", "discoverer": "Isaac Newton", "year": 1687, "field": "Physics"}', 'h167', true, 1),
('p3400001-0000-0000-0000-000000000003', '{"name": "Ideal Gas Law", "formula": "PV = nRT", "discoverer": "Émile Clapeyron", "year": 1834, "field": "Chemistry"}', 'h168', true, 1),
('p3400001-0000-0000-0000-000000000004', '{"name": "Planck-Einstein relation", "formula": "E = hv", "discoverer": "Max Planck", "year": 1900, "field": "Quantum Physics"}', 'h169', true, 1),
('p3400001-0000-0000-0000-000000000005', '{"name": "Ohm''s Law", "formula": "V = IR", "discoverer": "Georg Ohm", "year": 1827, "field": "Electronics"}', 'h170', true, 1),
-- theorem
('p3500001-0000-0000-0000-000000000001', '{"name": "Pythagorean Theorem", "formula": "a² + b² = c²", "discoverer": "Pythagoras", "year": -530, "field": "Geometry"}', 'h171', true, 1),
('p3500001-0000-0000-0000-000000000002', '{"name": "Euler''s Theorem", "formula": "a^φ(n) ≡ 1 (mod n)", "discoverer": "Leonhard Euler", "year": 1763, "field": "Number Theory"}', 'h172', true, 1),
('p3500001-0000-0000-0000-000000000003', '{"name": "Gödel''s Incompleteness Theorem", "description": "Any consistent system contains undecidable propositions", "discoverer": "Kurt Gödel", "year": 1931, "field": "Mathematical Logic"}', 'h173', true, 1),
('p3500001-0000-0000-0000-000000000004', '{"name": "Cantor''s Theorem", "description": "No set has same cardinality as its power set", "discoverer": "Georg Cantor", "year": 1891, "field": "Set Theory"}', 'h174', true, 1),
('p3500001-0000-0000-0000-000000000005', '{"name": "Bayes'' Theorem", "formula": "P(A|B) = P(B|A)P(A)/P(B)", "discoverer": "Thomas Bayes", "year": 1763, "field": "Probability"}', 'h175', true, 1),
-- software
('p3600001-0000-0000-0000-000000000001', '{"name": "Python", "version": "3.12", "license": "PSF", "language": "C", "paradigms": ["OOP", "Functional"], "first_release": 1991}', 'h176', true, 1),
('p3600001-0000-0000-0000-000000000002', '{"name": "PostgreSQL", "version": "16", "license": "PostgreSQL", "language": "C", "type": "RDBMS", "first_release": 1996}', 'h177', true, 1),
('p3600001-0000-0000-0000-000000000003', '{"name": "Docker", "version": "24.x", "license": "Apache 2.0", "language": "Go", "type": "Containerization", "first_release": 2013}', 'h178', true, 1),
('p3600001-0000-0000-0000-000000000004', '{"name": "VS Code", "version": "1.90", "license": "MIT", "language": "TypeScript", "type": "Code editor", "first_release": 2015}', 'h179', true, 1),
('p3600001-0000-0000-0000-000000000005', '{"name": "Git", "version": "2.45", "license": "GPL-2.0", "language": "C", "type": "Version control", "first_release": 2005, "creator": "Linus Torvalds"}', 'h180', true, 1),
-- game
('p3700001-0000-0000-0000-000000000001', '{"name": "The Witcher 3: Wild Hunt", "developer": "CD Projekt Red", "year": 2015, "genre": "RPG", "platforms": ["PC", "PS4", "Xbox One"], "rating": 9.3}', 'h181', true, 1),
('p3700001-0000-0000-0000-000000000002', '{"name": "Minecraft", "developer": "Mojang", "year": 2011, "genre": "Sandbox", "platforms": ["PC", "Console", "Mobile"], "rating": 9.0, "players": 140000000}', 'h182', true, 1),
('p3700001-0000-0000-0000-000000000003', '{"name": "Tetris", "developer": "Alexey Pajitnov", "year": 1984, "genre": "Puzzle", "platforms": ["Universal"], "rating": 8.5}', 'h183', true, 1),
('p3700001-0000-0000-0000-000000000004', '{"name": "Cyberpunk 2077", "developer": "CD Projekt Red", "year": 2020, "genre": "RPG", "platforms": ["PC", "PS5", "Xbox Series X"], "rating": 7.5}', 'h184', true, 1),
('p3700001-0000-0000-0000-000000000005', '{"name": "Half-Life", "developer": "Valve", "year": 1998, "genre": "FPS", "platforms": ["PC"], "rating": 9.5}', 'h185', true, 1),
-- podcast
('p3800001-0000-0000-0000-000000000001', '{"name": "Software Engineering Daily", "host": "Jeff Meyerson", "topic": "Technology", "frequency": "Daily", "episodes": 2000}', 'h186', true, 1),
('p3800001-0000-0000-0000-000000000002', '{"name": "Lex Fridman Podcast", "host": "Lex Fridman", "topic": "AI, Science, Philosophy", "frequency": "Weekly", "episodes": 400}', 'h187', true, 1),
('p3800001-0000-0000-0000-000000000003', '{"name": "The Joe Rogan Experience", "host": "Joe Rogan", "topic": "Various", "frequency": "Multiple times/week", "episodes": 2200}', 'h188', true, 1),
('p3800001-0000-0000-0000-000000000004', '{"name": "Hardcore History", "host": "Dan Carlin", "topic": "History", "frequency": "Monthly", "episodes": 70}', 'h189', true, 1),
('p3800001-0000-0000-0000-000000000005', '{"name": "Freakonomics Radio", "host": "Stephen Dubner", "topic": "Economics, Social science", "frequency": "Weekly", "episodes": 600}', 'h190', true, 1),
-- channel
('p3900001-0000-0000-0000-000000000001', '{"name": "Veritasium", "creator": "Derek Muller", "topic": "Science", "subscribers": 15000000, "platform": "YouTube"}', 'h191', true, 1),
('p3900001-0000-0000-0000-000000000002', '{"name": "Numberphile", "creator": "Brady Haran", "topic": "Mathematics", "subscribers": 4500000, "platform": "YouTube"}', 'h192', true, 1),
('p3900001-0000-0000-0000-000000000003', '{"name": "3Blue1Brown", "creator": "Grant Sanderson", "topic": "Mathematics", "subscribers": 5000000, "platform": "YouTube"}', 'h193', true, 1),
('p3900001-0000-0000-0000-000000000004', '{"name": "Kurzgesagt", "creator": "Philipp Dettmer", "topic": "Science, Philosophy", "subscribers": 20000000, "platform": "YouTube"}', 'h194', true, 1),
('p3900001-0000-0000-0000-000000000005', '{"name": "SmarterEveryDay", "creator": "Destin Sandlin", "topic": "Science", "subscribers": 10000000, "platform": "YouTube"}', 'h195', true, 1),
-- label_entity
('p4000001-0000-0000-0000-000000000001', '{"name": "Sony Music Entertainment", "founded": 1929, "headquarters": "New York", "genre": ["Pop", "Rock", "Hip-Hop"], "subsidiaries": ["Columbia", "RCA"]}', 'h196', true, 1),
('p4000001-0000-0000-0000-000000000002', '{"name": "Universal Music Group", "founded": 1934, "headquarters": "Santa Monica", "genre": ["Pop", "Rock", "Country"], "subsidiaries": ["Interscope", "Republic"]}', 'h197', true, 1),
('p4000001-0000-0000-0000-000000000003', '{"name": "Warner Music Group", "founded": 1958, "headquarters": "New York", "genre": ["Pop", "Rock", "Electronic"], "subsidiaries": ["Atlantic", "Warner Records"]}', 'h198', true, 1),
('p4000001-0000-0000-0000-000000000004', '{"name": "Def Jam Recordings", "founded": 1984, "headquarters": "New York", "genre": ["Hip-Hop", "R&B"], "founders": ["Russell Simmons", "Rick Rubin"]}', 'h199', true, 1),
('p4000001-0000-0000-0000-000000000005', '{"name": "Sub Pop", "founded": 1986, "headquarters": "Seattle", "genre": ["Indie Rock", "Grunge"], "notable_artists": ["Nirvana", "Soundgarden"]}', 'h200', true, 1);
