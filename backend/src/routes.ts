import { Router } from 'express';
import general from './modules/general';
import peopleToPeople from './modules/peopleToPeople';
import peopleToProject from './modules/peopleToProject';
import teamFormation from './modules/teamFormation';

// Titik gabung semua modul.
const router = Router();
router.use('/auth', general); // General Features: register/login/logout/profil
router.use('/people-to-people', peopleToPeople);
router.use('/people-to-project', peopleToProject);
router.use('/team-formation', teamFormation);
export default router;
