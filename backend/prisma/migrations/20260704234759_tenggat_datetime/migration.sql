-- Convert Lomba.tenggat from TEXT to TIMESTAMP(3). Existing values are free-form
-- test strings (e.g. "12 hari lagi") that cannot be parsed as dates, so the column
-- is dropped and recreated (data loss on this column only).
ALTER TABLE "Lomba" DROP COLUMN "tenggat";
ALTER TABLE "Lomba" ADD COLUMN "tenggat" TIMESTAMP(3);
